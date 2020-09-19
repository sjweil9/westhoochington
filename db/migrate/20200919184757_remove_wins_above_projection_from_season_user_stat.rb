class RemoveWinsAboveProjectionFromSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    remove_column :season_user_stats, :wins_above_projection, :integer
  end
end
