class AddOpponentProjectedTotalToGame < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :opponent_projected_total, :float
  end
end
