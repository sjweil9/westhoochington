class CreateFaabStats < ActiveRecord::Migration[5.2]
  def change
    create_table :faab_stats do |t|
      t.string :season_year
      t.json :biggest_load
      t.json :narrowest_fail
      t.json :biggest_overpay

      t.timestamps
    end
  end
end
