class AddStarterToBestBallGamePlayer < ActiveRecord::Migration[5.2]
  def change
    add_column :best_ball_game_players, :starter, :boolean
  end
end
