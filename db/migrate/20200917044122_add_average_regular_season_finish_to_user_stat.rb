class AddAverageRegularSeasonFinishToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :average_regular_season_finish, :numeric
  end
end
