class AddTotalPointsToBestBallLeagueUser < ActiveRecord::Migration[5.2]
  def change
    add_column :best_ball_league_users, :total_points, :numeric
  end
end
