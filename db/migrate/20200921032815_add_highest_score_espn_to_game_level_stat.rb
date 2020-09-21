class AddHighestScoreEspnToGameLevelStat < ActiveRecord::Migration[5.2]
  def change
    add_column :game_level_stats, :highest_score_espn, :json
  end
end
