class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.references :user, foreign_key: true
      t.integer :opponent_id
      t.integer :week
      t.integer :season_year
      t.float :active_total
      t.float :bench_total
      t.float :projected_total

      t.timestamps
    end
  end
end
