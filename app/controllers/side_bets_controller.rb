class SideBetsController < ApplicationController
  def index
    offset = Time.now.monday? ? 36 : 35
    @current_week = Time.now.strftime('%U').to_i - offset
    @current_year = Date.today.year
    @current_games =
      Game
        .unscoped
        .where(season_year: Date.today.year, week: @current_week)
        .includes(game_side_bets: :side_bet_acceptances)
        .references(game_side_bets: :side_bet_acceptances)
        .all
        .reject { |game| game.opponent_id > game.user_id }
    @active_players = @current_games.map { |game| [game.user, game.opponent] }.flatten
    @active_players.each(&:random_nickname) # make sure cache is primed always
  end

  def pending
    @pending_game_bets = GameSideBet
                      .where(status: %w[awaiting_payment awaiting_confirmation])
                      .includes(:side_bet_acceptances)
                      .references(:side_bet_acceptances)
                      .all
                      .map(&:side_bet_acceptances)
                      .flatten
    User.all.each(&:random_nickname) # make sure cache is primed always
  end

  def resolved

  end

  def create_game_bet
    create_params = new_game_side_bet_params
    create_params = handle_custom_params(create_params)
    side_bet = GameSideBet.new(create_params)
    unless side_bet.save
      process_errors(side_bet)
      flash[:create_bet_error] = true
    end
    redirect_to side_hustles_path
  end

  def accept_game_bet
    acceptance = SideBetAcceptance.new(side_bet_id: params[:side_bet_id], bet_type: 'game', user_id: current_user[:id])
    unless acceptance.save
      process_errors(acceptance)
      flash[:sba_error] = "Failed to accept side bet; please try again. Or complain to the asshole that runs this thing."
    end
    redirect_to side_hustles_path
  end

  private

  def new_game_side_bet_params
    params
      .permit(:game_id, :predicted_winner_id, :odds_for, :odds_against, :line, :acceptances_limit, :amount, acceptances_players: [])
      .merge(user_id: current_user[:id])
  end

  def handle_custom_params(params)
    limit = params.delete(:acceptances_limit)
    players = params.delete(:acceptances_players)
    json = { any: limit.blank? && players.blank?, max: limit.present? ? limit.to_i : false, users: players&.map(&:to_i) }
    odds = [params.delete(:odds_for), params.delete(:odds_against)].join(':')
    params.merge(possible_acceptances: json, odds: odds)
  end
end
