class CreateBestBallLeagueUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :best_ball_league_users do |t|
      t.references :best_ball_league, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
