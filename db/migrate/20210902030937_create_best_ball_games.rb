class CreateBestBallGames < ActiveRecord::Migration[5.2]
  def change
    create_table :best_ball_games do |t|
      t.references :best_ball_league, foreign_key: true
      t.integer :week
      t.numeric :total_points
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
