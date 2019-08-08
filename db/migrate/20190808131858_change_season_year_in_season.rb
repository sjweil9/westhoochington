class ChangeSeasonYearInSeason < ActiveRecord::Migration[5.2]
  def change
    change_column :seasons, :season_year, :integer
  end
end
