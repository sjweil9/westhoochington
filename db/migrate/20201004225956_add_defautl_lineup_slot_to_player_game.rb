class AddDefautlLineupSlotToPlayerGame < ActiveRecord::Migration[5.2]
  def change
    add_column :player_games, :default_lineup_slot, :string
  end
end
