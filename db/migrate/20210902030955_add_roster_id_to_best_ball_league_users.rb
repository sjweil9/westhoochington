class AddRosterIdToBestBallLeagueUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :best_ball_league_users, :roster_id, :string
    add_index :best_ball_league_users, :roster_id
  end
end
