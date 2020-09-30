class AddWonToSeasonSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :season_side_bets, :won, :boolean
  end
end
