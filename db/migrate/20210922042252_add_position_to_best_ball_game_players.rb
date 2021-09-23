class AddPositionToBestBallGamePlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :best_ball_game_players, :position, :string
  end
end
