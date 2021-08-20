class CreateWeeklySideBets < ActiveRecord::Migration[5.2]
  def change
    create_table :weekly_side_bets do |t|
      t.string :comparison_type
      t.json :bet_terms
      t.integer :season_year
      t.integer :week
      t.references :user, foreign_key: true
      t.string :status
      t.numeric :amount
      t.string :odds
      t.numeric :line

      t.timestamps
    end
  end
end
