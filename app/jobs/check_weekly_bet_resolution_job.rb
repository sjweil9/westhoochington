class CheckWeeklyBetResolutionJob < ApplicationJob
  queue_as :default

  def perform(season_year:, week:)
    @season_year = season_year
    @week = week
    games_for_week = Game.unscoped.where(season_year: season_year, week: week).all
    return unless games_for_week.size.positive? && games_for_week.all?(&:finished)

    pending_resolution_bets = WeeklySideBet.where(status: "awaiting_bets", season_year: season_year, week: week)
    pending_resolution_bets.each do |bet|
      calculate_winner(bet)
    end
  end

  private

  def calculate_winner(bet)
    method = "determine_#{bet.comparison_type}_result_values"
    bettor_value, acceptor_value = send(method, bet)
    evaluate_scores_method = "evaluate_#{bet.comparison_type}_scores"
    won = send(evaluate_scores_method, bettor_value, acceptor_value, bet)
    json = { bettor_value: bettor_value, acceptor_value: acceptor_value }
    bet.update(won: won, final_bet_results: json, status: 'awaiting_payment')
    bet.side_bet_acceptances.update_all(status: 'awaiting_payment')
    CalculateStatsJob.new.update_side_hustles(bet)
  end

  def determine_pvp_result_values(bet)
    winner_game = Game.find_by(season_year: @season_year, week: @week, user_id: bet.bet_terms["winner_id"])
    loser_game = Game.find_by(season_year: @season_year, week: @week, user_id: bet.bet_terms["loser_id"])
    [winner_game.active_total, loser_game.active_total]
  end

  def determine_over_under_result_values(bet)
    winner_game = Game.find_by(season_year: @season_year, week: @week, user_id: bet.bet_terms["player_id"])
    [winner_game.active_total, bet.bet_terms["line"].to_f]
  end

  def determine_high_score_result_values(bet)
    winner_game = Game.find_by(season_year: @season_year, week: @week, user_id: bet.bet_terms["winner_id"])
    other_games = Game.where(season_year: @season_year, week: @week).where.not(user_id: bet.bet_terms["winner_id"]).all
    [winner_game.active_total, other_games.map(&:active_total).max]
  end

  def evaluate_pvp_scores(bettor_value, acceptor_value, _bet)
    bettor_value > acceptor_value
  end

  def evaluate_over_under_scores(bettor_value, acceptor_value, bet)
    if bet.bet_terms["direction"] == "under"
      bettor_value < acceptor_value
    else
      acceptor_value > bettor_value
    end
  end

  def evaluate_high_score_scores(bettor_value, acceptor_value, _bet)
    bettor_value > acceptor_value
  end
end
