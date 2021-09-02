class AddSleeperIdToPlayers < ActiveRecord::Migration[5.2]
  def change
    add_column :players, :sleeper_id, :string
    add_index :players, :sleeper_id
  end
end
