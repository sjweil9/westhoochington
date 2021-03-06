class CreatePlayerGames < ActiveRecord::Migration[5.2]
  def change
    create_table :player_games do |t|
      t.references :player, foreign_key: true
      t.references :user, foreign_key: true
      t.references :game, foreign_key: true
      t.numeric :points
      t.boolean :active

      t.timestamps
    end
  end
end
