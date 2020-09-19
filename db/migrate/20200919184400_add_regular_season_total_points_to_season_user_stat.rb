class AddRegularSeasonTotalPointsToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :regular_season_total_points, :numeric
  end
end
