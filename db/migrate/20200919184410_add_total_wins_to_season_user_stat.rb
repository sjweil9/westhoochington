class AddTotalWinsToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :total_wins, :integer
  end
end
