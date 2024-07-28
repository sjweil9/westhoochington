class AddBestBallResultsToUserStats < ActiveRecord::Migration[6.1]
  def change
    add_column :user_stats, :best_ball_results, :json
  end
end
