class AddSleeperIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sleeper_id, :string
    add_index :users, :sleeper_id
  end
end
