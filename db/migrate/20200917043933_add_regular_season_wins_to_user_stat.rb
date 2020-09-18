class AddRegularSeasonWinsToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :regular_season_wins, :json
  end
end
