class AddCompletedDateToSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :side_bets, :completed_date, :datetime
  end
end
