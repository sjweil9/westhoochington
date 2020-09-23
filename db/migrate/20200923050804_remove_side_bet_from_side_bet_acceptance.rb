class RemoveSideBetFromSideBetAcceptance < ActiveRecord::Migration[5.2]
  def change
    remove_reference :side_bet_acceptances, :side_bet, foreign_key: true
  end
end
