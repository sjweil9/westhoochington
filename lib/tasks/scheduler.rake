namespace :stats do
  desc "This task is called by the Heroku scheduler add-on"
  task :load_weekly_data => :environment do
    # last scoring week still not complete, wait until Tuesday to load
    last_week = Time.now.strftime('%U').to_i - 36
    if Time.now.tuesday? && last_week.positive? && last_week <= 16
      current_year = Time.now.strftime('%Y')
      puts "Starting weekly data load for week #{last_week} year #{current_year}..."
      LoadWeeklyDataJob.perform_now(last_week, current_year)
      puts "Completed weekly data load."
    end
  end

  desc "This is also called by scheduler to load the next week of games"
  task :load_next_week_data => :environment do
    unless Time.now.monday? || Time.now.in_time_zone('America/Chicago').hour < 8
      current_week = Time.now.strftime('%U').to_i - 35
      current_year = Time.now.strftime('%Y')
      LoadWeeklyDataJob.perform_now(current_week, current_year, skip_calculated_stats: true)
    end
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
    last_week = Time.now.strftime('%U').to_i - 36

    # for current year, we just go up to the current week
    (1..last_week).to_a.each do |week|
      LoadWeeklyDataJob.perform_now(week, current_year)
    end
  end

  task :load_historical_data => :environment do
    current_year = Time.now.year
    (2015...current_year).each do |year|
      LoadWeeklyDataJob.new.perform_historical(year)
    end
  end

  task :load_season_data, [:year] => :environment do |_t, args|
    LoadWeeklyDataJob.new.perform_season_data(args[:year])
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
    end

    CalculateStatsJob.new.perform_game_level
  end
end

namespace :newsletter do
  desc "Called by Heroku scheduler to send newsletter"
  task :send => :environment do
    week = Time.now.strftime('%U').to_i - 36
    year = Date.today.year
    if Time.now.tuesday? && week.positive? && week <= 16
      relevant_week = [14, 16].include?(week) ? week - 1 : week
      involved_users = Game.where(season_year: year, week: relevant_week).map(&:user).reduce([]) { |emails, user| user.newsletter ? emails + [user.email] : emails }

      if week >= 13 && week <= 16
        UserNotificationsMailer.send_playoff_newsletter(involved_users, week, year).deliver
      elsif week <= 12
        UserNotificationsMailer.send_newsletter(involved_users, week, year).deliver
      end
    end
  end
end

namespace :bets do
  desc "Called by Heroku scheduler to update on any new action for the day"
  task :send_updates => :environment do
    BetNotificationsMailer.send_daily_update
  end
end