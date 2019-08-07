class AddSeasonYearToSeason < ActiveRecord::Migration[5.2]
  def change
    add_column :seasons, :season_year, :numeric
  end
end
