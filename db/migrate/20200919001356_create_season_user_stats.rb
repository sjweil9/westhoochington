class CreateSeasonUserStats < ActiveRecord::Migration[5.2]
  def change
    create_table :season_user_stats do |t|
      t.integer :season_year
      t.references :user, foreign_key: true
      t.integer :regular_season_place
      t.json :mir
      t.integer :weekly_high_scores
      t.numeric :average_margin
      t.integer :lucky_wins
      t.integer :unlucky_losses
      t.numeric :average_above_projection
      t.integer :wins_above_projection

      t.timestamps
    end
  end
end
