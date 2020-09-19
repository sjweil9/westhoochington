class AddRegularSeasonWinsToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :regular_season_wins, :integer
  end
end
