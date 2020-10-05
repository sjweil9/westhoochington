class Game < ApplicationRecord
  belongs_to :user
  belongs_to :opponent, class_name: 'User'
  has_many :game_side_bets
  has_many :player_games

  default_scope { where(finished: true) }

  def lineup
    player_games.lineup_order
  end

  after_update :set_bet_statuses

  def set_bet_statuses
    if saved_change_to_started? && self.started
      # update all associated bets (and side bet acceptances) to "awaiting_resolution"
      game_side_bets.where(status: 'awaiting_bets').each(&:game_started!)
    end

    if saved_change_to_finished? && self.finished
      # update all associated bets (and side bet acceptances) to "awaiting_payment" and update winner ID
      game_side_bets.where(status: 'awaiting_resolution').each(&:game_finished!)
    end
  end

  def winner
    won? ? user : opponent
  end

  def winner_id
    won? ? user_id : opponent_id
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
    return week > 14 if season_year < 2015
    return week >= 14 if season_year < 2018

    week >= 13
  end

  def espn?
    season_year >= 2015
  end

  def yahoo?
    season_year < 2015
  end

  def lucky?
    # won, but would have lost to opponent average score
    return false if lost?
    return (active_total / 2) < opponent.send("average_active_total_#{season_year}") if playoff? && season_year >= 2015
    
    active_total < opponent.send("average_active_total_#{season_year}")
  end

  def unlucky?
    # lost, but would have beaten opponent average score
    return false if won?
    return (active_total / 2) > opponent.send("average_active_total_#{season_year}") if playoff? && season_year >= 2015

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
    playoff_weighted_active_total - opponent.send("average_active_total_#{season_year}")
  end

  def points_above_average
    playoff_weighted_active_total - user.send("average_active_total_#{season_year}")
  end

  def playoff_weighted_active_total
    return active_total unless two_game_playoff?

    active_total / 2
  end

  def two_game_playoff?
    return false unless (13..16).cover?(week) && both_weeks_completed?

    Rails.cache.fetch("seasons.#{season_year}.two_game_playoff", expires_in: 1.days) do
      season = Season.find_by(season_year: season_year)
      season.nil? || season.two_game_playoff?
    end
  end

  def both_weeks_completed?
    season_year < Date.today.year || current_week > week
  end

  def current_week
    offset = (Time.now.sunday? || Time.now.monday?) ? 36 : 35
    Time.now.strftime('%U').to_i - offset
  end

  (1..17).each do |week_num|
    define_method(:"week#{week_num}?") { week == week_num }
  end
end
