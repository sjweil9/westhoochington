class CreateSeasonSideBets < ActiveRecord::Migration[5.2]
  def change
    create_table :season_side_bets do |t|
      t.integer :season_year
      t.references :user, foreign_key: true
      t.string :bet_type
      t.string :status
      t.json :bet_terms
      t.numeric :amount
      t.string :odds
      t.numeric :line
      t.string :comparison_type

      t.timestamps
    end
  end
end
