class RemoveWonFromSideBetAcceptance < ActiveRecord::Migration[5.2]
  def change
    remove_column :side_bet_acceptances, :won, :boolean
  end
end
