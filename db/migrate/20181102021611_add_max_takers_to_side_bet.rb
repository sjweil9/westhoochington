class AddMaxTakersToSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bets, :max_takers, :numeric
  end
end
