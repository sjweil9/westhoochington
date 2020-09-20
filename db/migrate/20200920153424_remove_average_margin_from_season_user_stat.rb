class RemoveAverageMarginFromSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    remove_column :season_user_stats, :average_margin, :string
  end
end
