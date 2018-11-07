class AddOpponentActiveTotalToGame < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :opponent_active_total, :float
  end
end
