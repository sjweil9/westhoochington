namespace :stats do
  desc "This task is called by the Heroku scheduler add-on"
  task :load_weekly_data => :environment do
    # last scoring week still not complete, wait until Tuesday to load
    return if Time.now.sunday? || Time.now.monday?

    current_year = Time.now.strftime('%Y')
    last_week = Time.now.strftime('%U').to_i - 35
    puts "Starting weekly data load for week #{last_week} year #{current_year}..."
    LoadWeeklyDataJob.perform_now(last_week, current_year)
    puts "Completed weekly data load."
  end

  desc "Called by Heroku scheduler to send newsletter"
  task :send_weekly_newsletter => :environment do
    week = Time.now.strftime('%U').to_i - 35
    year = Date.today.year
    return unless Time.now.tuesday? && week.positive?

    involved_users = Game.where(season_year: year, week: week).map(&:user)
    involved_users.each do |user|
      UserNotificationsMailer.send_newsletter(user, week, year)
    end
  end

  desc "This task would be run on demand"
  task :load_backlog_data => :environment do
    current_year = Time.now.year
    last_week = Time.now.strftime('%U').to_i - 35

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

  task :load_csv => :environment do
    LoadWeeklyDataJob.new.perform_csv
  end
end
