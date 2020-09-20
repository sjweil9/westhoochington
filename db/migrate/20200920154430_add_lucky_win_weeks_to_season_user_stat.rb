class AddLuckyWinWeeksToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :lucky_win_weeks, :json
  end
end
