class AddFinalBetResultsToSeasonSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :season_side_bets, :final_bet_results, :json
  end
end
