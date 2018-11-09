namespace :stats do
  desc "This task is called by the Heroku scheduler add-on"
  task :load_weekly_data => :environment do
    # last scoring week still not complete, wait until Tuesday to load
    return if Time.now.sunday? || Time.now.monday?

    last_week = Time.now.strftime('%U').to_i - 35
    puts "Starting weekly data load for week #{last_week}..."
    LoadWeeklyDataJob.perform_now(last_week)
    puts "Completed weekly data load."
    end

  desc "This task would be run on demand"
  task :load_backlog_data => :environment do
    last_week = Time.now.strftime('%U').to_i - 35

    (1..last_week).to_a.each do |week|
      LoadWeeklyDataJob.perform_now(week)
    end
  end
end
