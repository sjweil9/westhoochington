class AddStatusToSideBetAcceptance < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bet_acceptances, :status, :string
  end
end
