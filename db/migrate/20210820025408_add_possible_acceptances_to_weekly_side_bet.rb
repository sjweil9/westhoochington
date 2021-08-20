class AddPossibleAcceptancesToWeeklySideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :weekly_side_bets, :possible_acceptances, :json
  end
end
