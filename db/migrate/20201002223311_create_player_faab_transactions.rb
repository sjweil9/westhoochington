class CreatePlayerFaabTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :player_faab_transactions do |t|
      t.references :player, foreign_key: true
      t.references :user, foreign_key: true
      t.boolean :success
      t.integer :season_year
      t.integer :week
      t.integer :bid_amount
      t.integer :winning_bid

      t.timestamps
    end
  end
end
