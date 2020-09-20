class AddWinsAboveProjectionToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :wins_above_projection, :integer
  end
end
