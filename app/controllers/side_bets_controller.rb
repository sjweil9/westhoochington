class SideBetsController < ApplicationController
  before_action :prime_nickname_cache, only: %i[index pending resolved]

  def index
    offset = (Time.now.monday? || Time.now.sunday?) ? 36 : 35
    @current_week = Time.now.strftime('%U').to_i - offset
    @current_year = Date.today.year
    @current_games =
      Game
        .unscoped
        .where(season_year: Date.today.year, week: @current_week)
        .all
        .order(created_at: :desc)
        .reject { |game| game.opponent_id > game.user_id }
    @active_players = @current_games.map { |game| [game.user, game.opponent] }.flatten
    @open_season_bets = SeasonSideBet.where(status: %w[awaiting_resolution awaiting_bets]).includes(:side_bet_acceptances).references(:side_bet_acceptances).order(created_at: :desc).all
    @season_bet_types = SeasonSideBet::VALID_BET_TYPES
  end

  def pending
    @pending_game_bets = GameSideBet
                      .where(status: %w[awaiting_payment awaiting_confirmation])
                      .order(created_at: :desc)
                      .all
                      .map(&:side_bet_acceptances)
                      .flatten
    @pending_season_bets = SeasonSideBet
                             .where(status: %w[awaiting_payment awaiting_confirmation])
                             .order(created_at: :desc)
                             .all
                             .map(&:side_bet_acceptances)
                             .flatten
    @season_bet_types = SeasonSideBet::VALID_BET_TYPES
  end

  def resolved
    @year = params[:year] || Date.today.year
    @week = params[:week] || 'ALL'
    filter_year = @year == 'ALL' ? nil : @year
    filter_week = @week == 'ALL' ? nil : @week
    games = Game.unscoped.where({ season_year: filter_year, week: filter_week }.compact).all
    @resolved_game_bets = GameSideBet
                            .where(status: 'completed', game_id: games.map(&:id))
                            .order(created_at: :desc)
                            .all
                            .map(&:side_bet_acceptances)
                            .flatten
    @resolved_season_bets = SeasonSideBet
                              .where({ status: 'completed', season_year: filter_year }.compact)
                              .order(created_at: :desc)
                              .all
                              .map(&:side_bet_acceptances)
                              .flatten
    @season_bet_types = SeasonSideBet::VALID_BET_TYPES
  end

  def create_game_bet
    create_params = handle_custom_params(new_game_side_bet_params)
    side_bet = GameSideBet.new(create_params)
    unless side_bet.save
      process_errors(side_bet)
      flash[:create_bet_error] = true
    end
    redirect_to side_hustles_path
  end

  def create_season_bet
    create_params = handle_custom_season_params(new_season_side_bet_params)
    side_bet = SeasonSideBet.new(create_params)
    unless side_bet.save
      process_errors(side_bet)
      flash[:create_season_bet_error] = true
    end
    redirect_to side_hustles_path
  end

  def accept_bet
    acceptance = SideBetAcceptance.new(side_bet_id: params[:side_bet_id], bet_type: params[:bet_type], user_id: current_user[:id])
    unless acceptance.save
      process_errors(acceptance)
      flash[:sba_error] = "Failed to accept side bet; please try again. Or complain to the asshole that runs this thing."
    end
    redirect_to side_hustles_path
  end

  def confirm_payment_received
    acceptance = SideBetAcceptance.find(params[:acceptance_id])
    if acceptance.winner_id == current_user[:id]
      acceptance.confirm_payment!
    else
      flash[:payment_error] = "You cannot mark this payment received as you are not the winner of this bet."
    end
    redirect_to pending_bets_path
  end

  def mark_payment_sent
    acceptance = SideBetAcceptance.find(params[:acceptance_id])
    if [acceptance.winner_id, acceptance.loser_id].include?(current_user[:id])
      acceptance.mark_payment_sent!
    else
      flash[:payment_error] = "You cannot mark this payment sent as you are not involved in this bet."
    end
    redirect_to pending_bets_path
  end

  private

  SHARED_BET_PARAMS = [:odds_for, :odds_against, :line, :acceptances_limit, :amount, acceptances_players: []]

  def new_game_side_bet_params
    params
      .permit(:game_id, :predicted_winner_id, *SHARED_BET_PARAMS)
      .merge(user_id: current_user[:id])
  end

  def handle_custom_params(params)
    limit = params.delete(:acceptances_limit)
    players = params.delete(:acceptances_players)
    json = { any: limit.blank? && players.blank?, max: limit.present? ? limit.to_i : false, users: players&.map(&:to_i) }
    odds = [params.delete(:odds_for), params.delete(:odds_against)].join(':')
    params.merge(possible_acceptances: json, odds: odds)
  end

  def new_season_side_bet_params
    params
      .permit(:bet_type, :winner, :loser, :closing_date, :season_year, *SHARED_BET_PARAMS)
      .merge(user_id: current_user[:id])
  end

  def handle_custom_season_params(params)
    params = handle_custom_params(params)
    comparison_type = [params[:winner], params[:loser]].include?('field') ? '1VF': '1V1'
    terms = {
      winner_id: params[:winner] != 'field' ? params[:winner].to_i : nil,
      loser_id: params[:loser] != 'field' ? params[:loser].to_i : nil,
    }.compact
    params
      .except(:winner, :loser)
      .merge(
        comparison_type: comparison_type,
        bet_terms: terms,
        closing_date: Date.parse(params[:closing_date]).in_time_zone('America/Chicago').end_of_day
      )
  end

  def prime_nickname_cache
    User.all.each(&:random_nickname) # make sure cache is primed always
  end
end
