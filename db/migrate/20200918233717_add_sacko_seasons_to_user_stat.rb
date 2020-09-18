class AddSackoSeasonsToUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :user_stats, :sacko_seasons, :json
  end
end
