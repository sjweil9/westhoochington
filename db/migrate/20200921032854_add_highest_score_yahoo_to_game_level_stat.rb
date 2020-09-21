class AddHighestScoreYahooToGameLevelStat < ActiveRecord::Migration[5.2]
  def change
    add_column :game_level_stats, :highest_score_yahoo, :json
  end
end
