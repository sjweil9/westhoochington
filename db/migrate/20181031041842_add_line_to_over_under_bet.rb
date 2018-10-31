class AddLineToOverUnderBet < ActiveRecord::Migration[5.2]
  def change
    add_reference :over_under_bets, :line, foreign_key: true
  end
end
