class RemoveAverageAboveProjectionFromSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    remove_column :season_user_stats, :average_above_projection, :string
  end
end
