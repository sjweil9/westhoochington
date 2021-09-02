class CreateBestBallGamePlayers < ActiveRecord::Migration[5.2]
  def change
    create_table :best_ball_game_players do |t|
      t.references :player, foreign_key: true
      t.references :best_ball_game, foreign_key: true
      t.numeric :total_points

      t.timestamps
    end
  end
end
