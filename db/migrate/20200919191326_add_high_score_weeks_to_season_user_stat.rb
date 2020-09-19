class AddHighScoreWeeksToSeasonUserStat < ActiveRecord::Migration[5.2]
  def change
    add_column :season_user_stats, :high_score_weeks, :json
  end
end
