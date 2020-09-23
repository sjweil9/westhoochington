class AddLineToGameSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :game_side_bets, :line, :numeric
  end
end
