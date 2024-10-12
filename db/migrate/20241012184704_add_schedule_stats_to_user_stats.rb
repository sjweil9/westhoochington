class AddScheduleStatsToUserStats < ActiveRecord::Migration[6.1]
  def change
    add_column :user_stats, :schedule_stats, :json
  end
end
