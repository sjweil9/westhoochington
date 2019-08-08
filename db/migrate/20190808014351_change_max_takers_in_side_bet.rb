class ChangeMaxTakersInSideBet < ActiveRecord::Migration[5.2]
  def change
    change_column :side_bets, :max_takers, :integer
  end
end
