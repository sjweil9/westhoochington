class DropSideBetAcceptances < ActiveRecord::Migration[5.2]
  def change
    drop_table :side_bet_acceptances
  end
end
