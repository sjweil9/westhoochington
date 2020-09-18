class AddPlayoffRateToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :playoff_rate, :json
  end
end
