class AddUnluckyLossWeeksToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :unlucky_loss_weeks, :json
  end
end
