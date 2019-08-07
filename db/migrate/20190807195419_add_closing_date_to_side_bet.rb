class AddClosingDateToSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bets, :closing_date, :datetime
  end
end
