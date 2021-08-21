class AddFinalBetResultsToWeeklySideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :weekly_side_bets, :final_bet_results, :json
  end
end
