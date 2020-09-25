class AddClosingDateToSeasonSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :season_side_bets, :closing_date, :datetime
  end
end
