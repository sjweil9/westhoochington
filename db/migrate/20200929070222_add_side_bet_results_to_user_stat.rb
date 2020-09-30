class AddSideBetResultsToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :side_bet_results, :json
  end
end
