class AddAveragePointsEspnToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :average_points_espn, :numeric
  end
end
