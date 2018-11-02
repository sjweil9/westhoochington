class AddStatusToSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bets, :status, :string
  end
end
