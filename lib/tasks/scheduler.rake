namespace :stats do
  desc "This task is called by the Heroku scheduler add-on"
  task :load_weekly_data, [:override_day] => :environment do |_t, args|
    # last scoring week still not complete, wait until Tuesday to load
    last_week = Time.now.strftime('%U').to_i - 36
    if (Time.now.tuesday? && last_week.positive? && last_week <= 16) || args[:override_day]
      current_year = Time.now.strftime('%Y')
      puts "Starting weekly data load for week #{last_week} year #{current_year}..."
      LoadWeeklyDataJob.perform_now(last_week, current_year)
      puts "Completed weekly data load."
      games_for_week = Game.unscoped.where(season_year: current_year, week: last_week).all
      CheckWeeklyBetResolutionJob.new.perform(season_year: current_year, week: last_week) if games_for_week.size.positive? && games_for_week.all?(&:finished)
    end
  end

  desc "This is also called by scheduler to load the next week of games"
  task :load_next_week_data => :environment do
    unless Time.now.monday? || Time.now.in_time_zone('America/Chicago').hour < 7
      offset = Time.now.sunday? || Time.now.monday? ? 36 : 35
      current_week = Time.now.strftime('%U').to_i - offset
      current_year = Time.now.strftime('%Y')
      puts "Starting weekly data load for week #{current_week} year #{current_year}..."
      LoadWeeklyDataJob.perform_now(current_week, current_year, skip_calculated_stats: true)
      puts "Completed weekly data load."
    end
  end

  desc "Load all player data for this year to map ESPN IDs"
  task :load_players => :environment do
    LoadWeeklyDataJob.new.update_espn_players(Date.today.year)
  end

  desc "Used to load waiver transactions"
  task :load_waiver_transactions => :environment do
    current_week = Time.now.strftime('%U').to_i - 35
    if Time.now.thursday? && current_week.positive? && current_week <= 16
      current_year = Date.today.year
      LoadWeeklyDataJob.new.perform_transaction_data(current_year, current_week)
      CalculateStatsJob.new.update_faab(current_year)
      CalculateStatsJob.new.update_faab('alltime')
    end
  end

  desc "Used to load backlog transaction data"
  task :load_historical_transactions => :environment do
    current_year = Date.today.year
    (2018..current_year).each do |year|
      max_week = year == current_year ? Time.now.strftime('%U').to_i - 36 : 16
      (1..max_week).each do |week|
        LoadWeeklyDataJob.new.perform_transaction_data(year, week)
      end
      CalculateStatsJob.new.update_faab(year)
    end
    CalculateStatsJob.new.update_faab('alltime')
  end

  desc "Load on demand from Yahoo archives"
  task :load_yahoo_data => :environment do
    LoadWeeklyDataJob.new.perform_csv(yahoo: true)
  end

  desc "Load on demand seasons data from yahoo"
  task :load_yahoo_seasons => :environment do
    LoadWeeklyDataJob.new.perform_yahoo_seasons
  end

  desc "This task would be run on demand"
  task :load_backlog_data => :environment do
    current_year = Time.now.year
    (2018..current_year).each do |year|
      # for current year, we just go up to the current week
      max_week = year == current_year ? Time.now.strftime('%U').to_i - 36 : 16
      (1..max_week).to_a.each do |week|
        LoadWeeklyDataJob.perform_now(week, year)
      end
    end
  end

  task :load_historical_data => :environment do
    (2015..2017).each do |year|
      LoadWeeklyDataJob.new.perform_historical(year)
    end
  end

  task :load_season_data, [:year] => :environment do |_t, args|
    LoadWeeklyDataJob.new.perform_season_data(args[:year])
  end

  task :load_current_season => :environment do
    offset = Time.now.sunday? || Time.now.monday? ? 36 : 35
    current_week = Time.now.strftime('%U').to_i - offset
    return unless current_week > 16

    LoadWeeklyDataJob.new.perform_season_data(Date.today.year)
  end

  task :load_csv => :environment do
    LoadWeeklyDataJob.new.perform_csv
  end

  task :calculate_stats => :environment do
    User.all.each do |user|
      CalculateStatsJob.new.perform(user.id)
      (2012..Time.now.year).each do |year|
        CalculateStatsJob.new.perform_year(user.id, year)
      end
      CalculateStatsJob.new.update_side_hustle_stats(user)
    end

    CalculateStatsJob.new.perform_game_level
  end
end

namespace :newsletter do
  desc "Called by Heroku scheduler to send newsletter"
  task :send, [:override_day] => :environment do |_t, args|
    week = Time.now.strftime('%U').to_i - 36
    year = Date.today.year
    if (Time.now.tuesday? && week.positive? && week <= 16) || args[:override_day]
      relevant_week = [14, 16].include?(week) ? week - 1 : week
      involved_users = Game.where(season_year: year, week: relevant_week).map(&:user).reduce([]) { |emails, user| user.newsletter ? emails + [user.email] : emails }

      if week >= 13 && week <= 16
        involved_users = Game.unscoped.where(season_year: year, week: relevant_week).map(&:user).reduce([]) { |emails, user| user.newsletter ? emails + [user.email] : emails }
        UserNotificationsMailer.send_playoff_newsletter(involved_users, week, year).deliver
      elsif week <= 12
        UserNotificationsMailer.send_newsletter(involved_users, week, year).deliver
      end
    end
  end

  desc "Initial load for old yaml-based messages to new model"
  task :load_messages => :environment do
    NewsletterMessage::CATEGORIES.each do |category, object|
      object[:levels].each do |level|
        level = level[0]
        key = "newsletter.#{category}.#{level}"
        possible_values = I18n.t(key).values
        possible_values.each do |value|
          user = User.find_by(email: 'stephen.weil@gmail.com')
          message = NewsletterMessage.create(user_id: user.id, category: category, level: level, template_string: value)
          message.update(used: 1) # load initial ones as used so that any new contributions get precedence
        end
      end
    end
  end
end

EMAIL_DISCORD_MAPPING = {
  "stephen.weil@gmail.com" => "363522619435384834",
  "sccrrckstr@gmail.com" => "818951282575540224",
  "ovaisinamullah@gmail.com" => "695409268764967034",
  "mikelacy3@gmail.com" => "186243621039767553",
  "tonypelli@gmail.com" => "806630836576976936",
  "goblue101@gmail.com" => "710358726401458186",
  "pkaushish@gmail.com" => "869598426571087922",
  "adamkos101@gmail.com" => "698642107371356220",
  "captrf@gmail.com" => "869575333970599936",
  "seidmangar@gmail.com" => "873210954601594951",
  "michael.i.zack@gmail.com" => "206055078099025922",
  "john.rosensweig@gmail.com" => "363521698244591616"
}

EMAIL_SLEEPER_MAPPING = {
  "stephen.weil@gmail.com" => "469586445502246912",
  "sccrrckstr@gmail.com" => "473624636815306752",
  "ovaisinamullah@gmail.com" => "470746948761022464",
  "mikelacy3@gmail.com" => "469548265499521024",
  "goblue101@gmail.com" => "374409574377324544",
  "adamkos101@gmail.com" => "469597487510843392",
  "captrf@gmail.com" => "472209611479314432",
  "seidmangar@gmail.com" => "472100154690760704",
  "michael.i.zack@gmail.com" => "737182541722861568"
}

SLEEPER_LEAGUE_IDS = {
  "2021" => %w[737785373232623616 737553262500306944 735284283123548160]
}

namespace :discord do
  desc "Set discord IDs for all users"
  task :set_ids => :environment do
    EMAIL_DISCORD_MAPPING.each do |email, discord_id|
      User.find_by(email: email)&.update(discord_id: discord_id)
    end
  end
end

namespace :sleeper do
  desc "Set Sleeper IDs for all users"
  task :set_ids => :environment do
    EMAIL_SLEEPER_MAPPING.each do |email, sleeper_id|
      User.find_by(email: email)&.update(sleeper_id: sleeper_id)
    end
  end

  desc "Create Best Ball Leagues"
  task :create_leagues => :environment do
    SLEEPER_LEAGUE_IDS.each do |year, ids|
      ids.each do |id|
        record = BestBallLeague.find_or_create_by(sleeper_id: id, season_year: year)
        response = RestClient.get("https://api.sleeper.app/v1/league/#{id}")
        parsed = JSON.parse(response.body)
        record.update(name: parsed["name"])
      end
    end
  end

  desc "Update Sleeper IDs for all players"
  task :set_player_ids => :environment do
    response = RestClient.get("https://api.sleeper.app/v1/players/nfl")
    parsed = JSON.parse(response.body)
    parsed.each do |sleeper_id, object|
      espn_id = object["espn_id"]
      name = [object["first_name"], object["last_name"]].join(" ")
      player = Player.find_by("name = :name OR espn_id = :espn_id", name: name, espn_id: espn_id)
      player&.update(sleeper_id: sleeper_id)
    end
  end

  desc "Updates overall results for a league"
  task :update_leagues, [:season_year] => :environment do |_t, args|
    season_year = args[:season_year]
    SLEEPER_LEAGUE_IDS[season_year].each do |league_id|
      Sleeper::UpdateBestBallResultsJob.perform_now(league_id)
    end
  end

  desc "Updates results for a week"
  task :update_week => :environment do
    previous_week = Time.now.strftime('%U').to_i - 36
    if Time.now.tuesday? && previous_week.positive? && previous_week <= 18
      SLEEPER_LEAGUE_IDS[Date.current.year.to_s].each do |league_id|
        Sleeper::UpdateBestBallResultsJob.perform_now(league_id)
        Sleeper::UpdateBestBallWeekJob.perform_now(league_id, previous_week)
      end

      state_response = RestClient.get("https://api.sleeper.app/v1/state/nfl")
      parsed = JSON.parse(state_response.body)
      if parsed["week"] > previous_week.to_i
        Discord::Messages::BestBallUpdateJob.perform_now(previous_week)
      end
    end
  end
end

namespace :users do
  desc "Set active users"
  task :set_active => :environment do
    EMAIL_DISCORD_MAPPING.each do |email, _|
      User.find_by(email: email)&.update(active: true)
    end
  end
end

namespace :bets do
  desc "Called by Heroku scheduler to update on any new action for the day"
  task :send_updates => :environment do
    BetNotificationsMailer.send_daily_update&.deliver
  end

  desc "Updates status on seasonal bets that are past their closed date"
  task :update_seasonal_bets => :environment do
    closed_bets = SeasonSideBet.where('closing_date < ?', Time.now.in_time_zone('America/Chicago').utc).where(status: 'awaiting_bets')
    closed_bets.update_all(status: 'awaiting_resolution')
  end

  desc "Checks season bets for resolution"
  task :check_season_bet_resolution => :environment do
    CheckSeasonBetResolutionJob.new.perform
  end
end