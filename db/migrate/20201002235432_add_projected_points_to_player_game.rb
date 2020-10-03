class AddProjectedPointsToPlayerGame < ActiveRecord::Migration[5.2]
  def change
    add_column :player_games, :projected_points, :numeric
  end
end
