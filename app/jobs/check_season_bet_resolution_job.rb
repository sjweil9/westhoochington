class CheckSeasonBetResolutionJob < ApplicationJob
  queue_as :default

  def perform
    pending_resolution_bets = SeasonSideBet.where(status: 'awaiting_resolution')
    pending_resolution_bets.each do |bet|
      if bet.regular_season?
        calculate_winner(bet) if regular_season_completed?(bet.season_year)
      else
        calculate_winner(bet) if full_season_completed?(bet.season_year)
      end
    end
  end

  private

  def calculate_winner(bet)
    LoadWeeklyDataJob.new.perform_season_data(bet.season_year) # make sure seasons data is updated before calculating
    bettor_value, acceptor_value = determine_result_values(bet)
    won = bettor_value + bet.line > acceptor_value
    bet.update(won: won)
  end

  def determine_result_values(bet)
    if bet.player_vs_field?
      determine_pvf_result_value(bet)
    elsif bet.player_vs_player?
      determine_pvp_result_value(bet)
    end
  end

  def determine_pvf_result_value(bet)
    comparison_method = if bet.regular_season_points?
                          :"regular_yearly_active_total_#{bet.season_year}"
                        elsif bet.regular_season_finish?
                          :"regular_rank_#{bet.season_year}"
                        elsif bet.final_standings?
                          :"playoff_rank_#{bet.season_year}"
                        elsif bet.total_points?
                          :"yearly_active_total_#{bet.season_year}"
                        end

    if bet.bet_terms['winner_id']
      # bet picked the user
      winner = User.find(bet.bet_terms['winner_id'])
      other_users = Season.where(season_year: bet.season_year).all.map(&:user).reject { |user| user.id == winner.id }
      [winner.send(comparison_method), other_users.map(&comparison_method).max]
    else
      # bet picked the field
      loser = User.find(bet.bet_terms['loser_id'])
      other_users = Season.where(season_year: bet.season_year).all.map(&:user).reject { |user| user.id == loser.id }
      [other_users.map(&comparison_method).max, loser.send(comparison_method)]
    end
  end

  def determine_pvp_result_value(bet)
    predicted_winner = User.find(bet.bet_terms['winner_id'])
    predicted_loser = user.find(bet.bet_terms['loser_id'])
    if bet.regular_season_points?
      method = "regular_yearly_active_total_#{bet.season_year}"
      [predicted_winner.send(method), predicted_loser.send(method)]
    elsif bet.regular_season_finish?
      method = "season_#{bet.season_year}"
      [predicted_winner.send(method).regular_rank.to_i, predicted_loser.send(method).regular_rank.to_i]
    elsif bet.final_standings?
      method = "season_#{bet.season_year}"
      [predicted_winner.send(method).playoff_rank.to_i, predicted_loser.send(method).playoff_rank.to_i]
    elsif bet.total_points
      method = "yearly_active_total_#{bet.season_year}"
      [predicted_winner.send(method), predicted_loser.send(method)]
    end
  end

  def regular_season_completed?(year)
    return true
    return true if year < Date.today.year

    current_week = Time.now.strftime('%U').to_i - 35
    current_week >= 13
  end

  def full_season_completed?(year)
    return true if year < Date.today.year

    current_week = Time.now.strftime('%U').to_i - 35
    current_week > 16
  end
end
