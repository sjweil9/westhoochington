class AddSideBetIdToSideBetAcceptance < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bet_acceptances, :side_bet_id, :integer
  end
end
