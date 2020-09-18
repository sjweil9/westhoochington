class AddAveragePointsYahooToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :average_points_yahoo, :numeric
  end
end
