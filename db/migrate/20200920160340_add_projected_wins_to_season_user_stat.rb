class AddProjectedWinsToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :projected_wins, :integer
  end
end
