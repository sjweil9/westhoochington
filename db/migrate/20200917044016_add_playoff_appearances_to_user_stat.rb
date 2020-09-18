class AddPlayoffAppearancesToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :playoff_appearances, :json
  end
end
