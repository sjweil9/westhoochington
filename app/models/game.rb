class Game < ApplicationRecord
  belongs_to :user
  belongs_to :opponent, class_name: 'User'

  def winner
    won? ? user : opponent
  end

  def loser
    won? ? opponent : user
  end

  def winning_score
    won? ? active_total : opponent_active_total
  end

  def losing_score
    won? ? opponent_active_total : active_total
  end

  def won?
    active_total > opponent_active_total
  end

  def lost?
    opponent_active_total > active_total
  end

  def projected_win?
    projected_total > opponent_projected_total
  end

  def playoff?
    return week >= 14 if season_year < 2018

    week >= 13
  end

  def lucky?
    # won, but would have lost to opponent average score
    return false if lost?
    
    active_total < opponent.send("average_active_total_#{season_year}")
  end

  def unlucky?
    # lost, but would have beaten opponent average score
    return false if won?

    active_total > opponent.send("average_active_total_#{season_year}")
  end

  def weekly_high_score?(passed_games = nil)
    return false if lost?

    other_week_games = 
      if passed_games
        passed_games&.select { |pg| pg.season_year == season_year && pg.week == week && pg.user_id != user_id }
      else
        Game.where(season_year: season_year, week: week).where.not(user_id: user_id).all
      end
    other_week_games.none? { |game| game.active_total > active_total }
  end

  def margin
    (active_total - opponent_active_total).round(2)
  end

  def margin_of_victory
    won? ? margin : -margin
  end

  def points_above_projection
    active_total - projected_total
  end

  def points_above_opponent_average
    active_total - opponent.send("average_active_total_#{season_year}")
  end

  def points_above_average
    active_total - user.send("average_active_total_#{season_year}")
  end

  (1..17).each do |week_num|
    define_method(:"week#{week_num}?") { week == week_num }
  end
end
