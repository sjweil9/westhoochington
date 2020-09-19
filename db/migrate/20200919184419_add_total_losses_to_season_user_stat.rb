class AddTotalLossesToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :total_losses, :integer
  end
end
