class AddLineupSlotToPlayerGame < ActiveRecord::Migration[5.2]
  def change
    add_column :player_games, :lineup_slot, :string
  end
end
