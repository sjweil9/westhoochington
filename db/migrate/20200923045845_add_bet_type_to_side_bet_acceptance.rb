class AddBetTypeToSideBetAcceptance < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bet_acceptances, :bet_type, :string
  end
end
