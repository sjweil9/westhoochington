class CreateGameLevelStats < ActiveRecord::Migration[5.2]
  def change
    create_table :game_level_stats do |t|
      t.json :highest_score
      t.json :lowest_score
      t.json :largest_margin
      t.json :narrowest_margin

      t.timestamps
    end
  end
end
