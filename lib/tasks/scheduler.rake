desc "This task is called by the Heroku scheduler add-on"
task :load_weekly_data => :environment do
  return unless Time.now.tuesday?

  week = Time.now.strftime('%U').to_i - 34
  puts "Starting weekly data load for week #{week}..."
  LoadWeeklyData.perform_now(week)
  puts "Completed weekly data load."
end

task :load_backlog_data => :environment do
  current_week = Time.now.strftime('%U').to_i - 34

  (1...current_week).to_a.each do |week|
    LoadWeeklyData.perform_now(week)
  end
end
