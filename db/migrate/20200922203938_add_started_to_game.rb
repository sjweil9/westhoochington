class AddStartedToGame < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :started, :boolean
  end
end
