class RemoveOverUnderFromOverUnderBet < ActiveRecord::Migration[5.2]
  def change
    remove_reference :over_under_bets, :over_under, foreign_key: true
  end
end
