class Game < ApplicationRecord
  belongs_to :user
  belongs_to :opponent, class_name: 'User'

  def won?
    active_total > opponent_active_total
  end

  def lost?
    opponent_active_total > active_total
  end

  def lucky?
    # won, but would have lost to opponent average score
    return false if lost?
    
    active_total < opponent.average_active_total
  end

  def weekly_high_score?
    return false if lost?

    other_week_games = Game.where(season_year: season_year, week: week).where.not(user_id: user_id).all
    other_week_games.none? { |game| game.active_total > active_total }
  end

  def point_differential
    active_total - opponent_active_total
  end
end
