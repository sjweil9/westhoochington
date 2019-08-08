class AddPaidToSideBetAcceptance < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bet_acceptances, :paid, :boolean
  end
end
