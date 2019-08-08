class AddPaidToSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bets, :paid, :boolean
  end
end
