class AddPossibleAcceptancesToSeasonSideBet < ActiveRecord::Migration[5.2]
  def change
    add_column :season_side_bets, :possible_acceptances, :json
  end
end
