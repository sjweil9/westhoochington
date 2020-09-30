class CreateGameSideBets < ActiveRecord::Migration[5.2]
  def change
    create_table :game_side_bets do |t|
      t.references :game, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :predicted_winner_id
      t.string :status
      t.integer :actual_winner_id
      t.numeric :amount
      t.string :odds
      t.json :possible_acceptances

      t.timestamps
    end
  end
end
