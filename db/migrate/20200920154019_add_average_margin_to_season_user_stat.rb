class AddAverageMarginToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :average_margin, :numeric
  end
end
