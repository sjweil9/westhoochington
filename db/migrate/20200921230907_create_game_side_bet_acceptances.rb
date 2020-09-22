class CreateGameSideBetAcceptances < ActiveRecord::Migration[5.2]
  def change
    create_table :game_side_bet_acceptances do |t|
      t.references :user, foreign_key: true
      t.references :game_side_bet, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
