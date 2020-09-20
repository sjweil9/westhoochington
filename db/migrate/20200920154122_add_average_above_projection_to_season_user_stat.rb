class AddAverageAboveProjectionToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :average_above_projection, :numeric
  end
end
