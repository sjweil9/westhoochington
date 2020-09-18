class AddAverageMarginToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :average_margin, :numeric
  end
end
