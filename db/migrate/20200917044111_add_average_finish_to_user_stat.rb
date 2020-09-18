class AddAverageFinishToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :average_finish, :numeric
  end
end
