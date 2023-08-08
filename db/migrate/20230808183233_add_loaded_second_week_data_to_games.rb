class AddLoadedSecondWeekDataToGames < ActiveRecord::Migration[6.1]
  def change
    add_column :games, :loaded_second_week_data, :boolean
  end
end
