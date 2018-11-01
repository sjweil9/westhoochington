class AddCompletedToSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bets, :completed, :boolean
  end
end
