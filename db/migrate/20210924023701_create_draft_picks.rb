class CreateDraftPicks < ActiveRecord::Migration[5.2]
  def change
    create_table :draft_picks do |t|
      t.references :user, foreign_key: true
      t.integer :season_year
      t.string :league_id
      t.string :league_platform
      t.string :drafted_league_id
      t.string :drafted_league_platform
      t.string :draft_id
      t.references :player, foreign_key: true
      t.string :draft_type
      t.integer :overall_pick_number
      t.integer :round_number
      t.integer :round_pick_number
      t.integer :bid_amount

      t.timestamps
    end
  end
end
