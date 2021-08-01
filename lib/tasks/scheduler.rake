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

  desc "Used to load waiver transactions"
  task :load_waiver_transactions => :environment do
    current_week = Time.now.strftime('%U').to_i - 35
    if Time.now.thursday? && current_week.positive? && current_week <= 16
      current_year = Date.today.year
      LoadWeeklyDataJob.new.perform_transaction_data(current_year, current_week)
      CalculateStatsJob.new.update_faab(current_year)
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
  "mikelacy3@gmail.com" => "",
  "tonypelli@gmail.com" => "",
  "goblue101@gmail.com" => "710358726401458186",
  "pkaushish@gmail.com" => "869598426571087922",
  "adamkos101@gmail.com" => "698642107371356220",
  "captrf@gmail.com" => "869575333970599936",
  "seidmangar@gmail.com" => "",
  "michael.i.zack@gmail.com" => "206055078099025922",
  "john.rosensweig@gmail.com" => "363521698244591616"
}

namespace :discord do
  desc "Set discord IDs for all users"
  task :set_ids => :environment do
    EMAIL_DISCORD_MAPPING.each do |email, discord_id|
      User.find_by(email: email)&.update(discord_id: discord_id)
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