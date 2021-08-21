class AddWonToWeeklySideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :weekly_side_bets, :won, :boolean
  end
end
