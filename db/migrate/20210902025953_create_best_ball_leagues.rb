class CreateBestBallLeagues < ActiveRecord::Migration[5.2]
  def change
    create_table :best_ball_leagues do |t|
      t.string :name
      t.string :sleeper_id
      t.integer :season_year

      t.timestamps
    end
    add_index :best_ball_leagues, :sleeper_id
  end
end
