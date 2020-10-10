class CalculateStatsJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    calculated_stats = user.calculated_stats || UserStat.create(user_id: user.id)
    update_mir(user, calculated_stats)
    update_championships(user, calculated_stats)
    update_second_places(user, calculated_stats)
    update_sacko_seasons(user, calculated_stats)
    update_regular_season_wins(user, calculated_stats)
    update_average_finish(user, calculated_stats)
    update_average_regular_season_finish(user, calculated_stats)
    update_playoff_rate(user, calculated_stats)
    update_average_points_espn(user, calculated_stats)
    update_average_points_yahoo(user, calculated_stats)
    update_average_margin(user, calculated_stats)
    update_lifetime_record(user, calculated_stats)
  end

  def perform_year(user_id, year)
    user = User.find(user_id)
    calculated_stats = user.send("calculated_stats_#{year}") || SeasonUserStat.create(user_id: user.id, season_year: year)
    update_regular_season_totals(user, year, calculated_stats)
    update_final_totals(user, year, calculated_stats)
    update_year_mir(user, year, calculated_stats)
    update_high_scores(user, year, calculated_stats)
    update_scoring_averages(user, year, calculated_stats)
    update_lucky_weeks(user, year, calculated_stats)
    update_unlucky_weeks(user, year, calculated_stats)
  end

  def perform_game_level
    update_highest_score
    update_highest_score_espn
    update_highest_score_yahoo
    update_lowest_score
    update_largest_margin
    update_narrowest_margin
  end

  def update_side_hustles(side_bet)
    users = [side_bet.user, *side_bet.side_bet_acceptances.map(&:user)]
    users.each do |user|
      update_side_hustle_stats(user)
    end
  end

  def update_side_hustle_stats(user)
    calculated_stats = user.calculated_stats || UserStat.create(user_id: user.id)
    json = {
      wins: user.side_bet_wins,
      losses: user.side_bet_losses,
      winrate: user.side_bet_winrate,
      proposed: user.side_bets_proposed,
    }
    calculated_stats.update(side_bet_results: json)
  end

  def update_faab(year)
    calculated_stats = FaabStat.find_by(season_year: year) || FaabStat.create(season_year: year)
    filter_params = { season_year: year == 'alltime' ? nil : year }.compact
    update_biggest_load(calculated_stats, filter_params)
    update_narrowest_fail(calculated_stats, filter_params)
    update_biggest_overpay(calculated_stats, filter_params)
    update_most_impactful(calculated_stats, filter_params)
    update_most_impactful_ppg(calculated_stats, filter_params)
    update_most_impactful_ppd(calculated_stats, filter_params)
  end

  ###########################################################################################
  #                                 SEASONAL STATS                                          #
  ###########################################################################################

  def update_regular_season_totals(user, year, calculated_stats)
    games = user.send("games_#{year}").reject(&:playoff?)
    wins = games.select(&:won?).size
    losses = games.select(&:lost?).size
    points = games.map(&:active_total).reduce(:+).to_f.round(2)
    calculated_stats.update(regular_season_wins: wins, regular_season_losses: losses, regular_season_total_points: points)
  end

  def update_final_totals(user, year, calculated_stats)
    games = user.send("games_#{year}")
    wins = games.select(&:won?).size
    losses = games.select(&:lost?).size
    points = games.map(&:active_total).reduce(:+).to_f.round(2)
    if year >= 2018
      projected_wins = user.send("projected_wins_#{year}")
      wins_above_projection = wins - projected_wins
    end
    calculated_stats.update(
      total_wins: wins,
      total_losses: losses,
      total_points: points,
      projected_wins: projected_wins,
      wins_above_projection: wins_above_projection
    )
  end

  def update_year_mir(user, year, calculated_stats)
    record_string = user.matchup_independent_record(nil, year)
    point_value = user.points_for_mir(record_string)
    json_hash = {
      points: point_value,
      record_string: record_string,
    }
    calculated_stats.update(mir: json_hash)
  end

  def update_high_scores(user, year, calculated_stats)
    games = Game.where(season_year: year).reject(&:playoff?)
    high_scores = user.send("games_#{year}").reject(&:playoff?).select { |game| game.weekly_high_score?(games) }
    weeks = high_scores.map do |game|
      { week: game.week, opponent_id: game.opponent_id }
    end
    calculated_stats.update(weekly_high_scores: high_scores.size, high_score_weeks: weeks)
  end

  def update_scoring_averages(user, year, calculated_stats)
    average_scored = user.send("average_active_total_#{year}")
    average_opponent_scored = user.send("average_opponent_active_total_#{year}")
    average_margin = average_scored - average_opponent_scored
    if year >= 2018
      average_projected = user.send("average_projected_total_#{year}")
      average_above_projection = average_scored - average_projected
    end
    calculated_stats.update(
      average_points: average_scored,
      average_projected_points: average_projected,
      average_opponent_points: average_opponent_scored,
      average_margin: average_margin.round(2),
      average_above_projection: average_above_projection&.round(2)
    )
  end

  def update_lucky_weeks(user, year, calculated_stats)
    lucky_win_games = user.send("games_#{year}").select(&:lucky?)
    lucky_win_weeks = lucky_win_games.map do |game|
      { week: game.week, opponent_id: game.opponent.id }
    end
    calculated_stats.update(lucky_wins: lucky_win_games.size, lucky_win_weeks: lucky_win_weeks)
  end

  def update_unlucky_weeks(user, year, calculated_stats)
    unlucky_loss_games = user.send("games_#{year}").select(&:unlucky?)
    unlucky_loss_weeks = unlucky_loss_games.map do |game|
      { week: game.week, opponent_id: game.opponent.id }
    end
    calculated_stats.update(unlucky_losses: unlucky_loss_games.size, unlucky_loss_weeks: unlucky_loss_weeks)
  end

  ###########################################################################################
  #                                 ALL TIME STATS                                          #
  ###########################################################################################

  def update_mir(user, calculated_stats)
    json_hash = [*user.seasons.map(&:season_year), 'alltime'].reduce({}) do |hash, year|
      games = if year == 'alltime'
                user.games_from_involved_seasons
              else
                Game.where(season_year: year.to_i)
              end
      record_string = user.matchup_independent_record(games, year)
      point_value = user.points_for_mir(record_string)
      hash.merge(year => { points: point_value, record_string: record_string })
    end

    calculated_stats.update(mir: json_hash)
  end

  def update_championships(user, calculated_stats)
    json_hash = {
      wins: user.seasons.select(&:championship?).size,
      seasons: user.championship_seasons.map(&:season_year).map(&:to_i).join(', '),
    }
    calculated_stats.update(championships: json_hash)
  end

  def update_second_places(user, calculated_stats)
    json_hash = {
      count: user.seasons.select(&:second_place?).size,
      seasons: user.second_place_seasons.map(&:season_year).map(&:to_i).join(', '),
    }
    calculated_stats.update(second_place_finishes: json_hash)
  end

  def update_regular_season_wins(user, calculated_stats)
    json_hash = {
      count: user.seasons.select(&:regular_season_win?).size,
      seasons: user.regular_season_win_seasons.map(&:season_year).map(&:to_i).join(', '),
    }
    calculated_stats.update(regular_season_wins: json_hash)
  end

  def update_sacko_seasons(user, calculated_stats)
    json_hash = {
      count: user.seasons.select(&:sacko?).size,
      seasons: user.sacko_seasons.map(&:season_year).map(&:to_i).join(', ')
    }
    calculated_stats.update(sacko_seasons: json_hash)
  end

  def update_average_finish(user, calculated_stats)
    season_count = user.seasons.size
    calculated_stats.update(average_finish: (user.seasons.map(&:playoff_rank).reduce(:+) / season_count.to_f).round(2))
  end

  def update_average_regular_season_finish(user, calculated_stats)
    season_count = user.seasons.size
    calculated_stats.update(average_regular_season_finish: (user.seasons.map(&:regular_rank).reduce(:+) / season_count.to_f).round(2))
  end

  def update_playoff_rate(user, calculated_stats)
    total = user.seasons.size
    playoffs = user.seasons.select(&:playoff_appearance?).size
    rate = ((playoffs.to_f / total.to_f) * 100.0).round(2)
    json_hash = {
      rate: rate,
      playoffs: playoffs,
      total: total
    }
    calculated_stats.update(playoff_rate: json_hash)
  end

  def update_average_points_espn(user, calculated_stats)
    points = user.calculate_average_points_scored('espn')
    calculated_stats.update(average_points_espn: points)
  end

  def update_average_points_yahoo(user, calculated_stats)
    points = user.calculate_average_points_scored('yahoo')
    calculated_stats.update(average_points_yahoo: points)
  end

  def update_average_margin(user, calculated_stats)
    games_played = user.historical_games.size + (2 * user.seasons.select(&:two_game_playoff?).size)
    margin = (user.historical_games.map(&:margin).reduce(:+) / games_played.to_f).round(2)
    calculated_stats.update(average_margin: margin)
  end

  def update_lifetime_record(user, calculated_stats)
    json_hash = User.all.reduce({}) do |memo, opponent|
      if opponent.id == user.id
        memo
      else
        record_string = user.calculate_lifetime_record_against(opponent.id)
        color = color_for_record_string(record_string)
        memo.merge(opponent.id.to_s => {
          record_string: record_string,
          color: color
        })
      end
    end
    calculated_stats.update(lifetime_record: json_hash)
  end

  def color_for_record_string(string)
    win, loss, _draw = string.split(' - ').map(&:to_i)
    if win > loss
      'green-bg'
    elsif loss > win
      'red-bg'
    else
      ''
    end
  end

  ###########################################################################################
  #                                 GAME LEVEL STATS                                        #
  ###########################################################################################

  def update_highest_score
    highest_scores = Game.order(active_total: :desc).all.reject { |g| g.playoff? && two_game_playoff_years[g.season_year.to_s] }.first(10)
    json = highest_scores.map do |game|
      { year: game.season_year, week: game.week, player_id: game.user_id, opponent_id: game.opponent_id, score: game.active_total }
    end
    GameLevelStat.first_or_create.update(highest_score: json)
  end

  def update_highest_score_espn
    highest_scores = Game.where('season_year >= ?', 2015).order(active_total: :desc).all.reject(&:playoff?).first(10)
    json = highest_scores.map do |game|
      { year: game.season_year, week: game.week, player_id: game.user_id, opponent_id: game.opponent_id, score: game.active_total }
    end
    GameLevelStat.first_or_create.update(highest_score_espn: json)
  end

  def update_highest_score_yahoo
    highest_scores = Game.where('season_year < ?', 2015).order(active_total: :desc).first(10)
    json = highest_scores.map do |game|
      { year: game.season_year, week: game.week, player_id: game.user_id, opponent_id: game.opponent_id, score: game.active_total }
    end
    GameLevelStat.first_or_create.update(highest_score_yahoo: json)
  end

  def update_lowest_score
    lowest_scores = Game.order(active_total: :asc).all.reject { |g| g.playoff? && two_game_playoff_years[g.season_year.to_s] }.first(10)
    json = lowest_scores.map do |game|
      { year: game.season_year, week: game.week, player_id: game.user_id, opponent_id: game.opponent_id, score: game.active_total }
    end
    GameLevelStat.first_or_create.update(lowest_score: json)
  end

  def update_largest_margin
    largest_margins = Game.order(Arel.sql('active_total - opponent_active_total') => :desc).all.reject { |g| g.playoff? && two_game_playoff_years[g.season_year.to_s] }.first(10)
    json = largest_margins.map do |game|
      {
        year: game.season_year,
        week: game.week,
        player_id: game.user_id,
        opponent_id: game.opponent_id,
        score: game.active_total,
        opponent_score: game.opponent_active_total,
        margin: game.active_total - game.opponent_active_total
      }
    end
    GameLevelStat.first_or_create.update(largest_margin: json)
  end

  def update_narrowest_margin
    narrowest_margins = Game.where(Arel.sql('active_total < opponent_active_total')).order(Arel.sql('ABS(active_total - opponent_active_total)') => :asc).all.reject { |g| g.playoff? && two_game_playoff_years[g.season_year.to_s] }.first(10)
    json = narrowest_margins.map do |game|
      {
        year: game.season_year,
        week: game.week,
        player_id: game.user_id,
        opponent_id: game.opponent_id,
        score: game.active_total,
        opponent_score: game.opponent_active_total,
        margin: game.active_total - game.opponent_active_total
      }
    end
    GameLevelStat.first_or_create.update(narrowest_margin: json)
  end

  def two_game_playoff_years
    @two_game_playoff_years ||= Season.all.reduce({}) do |memo, season|
      memo.merge(season.season_year.to_s => season.two_game_playoff?)
    end
  end

  ##################################################################################
  #                          FAAB METHODS                                          #
  ##################################################################################

  def update_biggest_load(calculated_stats, filter_params)
    transactions = PlayerFaabTransaction.where(filter_params).order(bid_amount: :desc).first(10)
    json = transactions.map do |transaction|
      {
        user_id: transaction.user_id,
        year: transaction.season_year,
        week: transaction.week,
        player_id: transaction.player_id,
        amount: transaction.bid_amount,
        success: transaction.success,
      }
    end
    calculated_stats.update(biggest_load: json)
  end

  def update_narrowest_fail(calculated_stats, filter_params)
    transactions = PlayerFaabTransaction.where(filter_params.merge(success: false)).order('winning_bid - bid_amount ASC').first(10)
    json = transactions.map do |transaction|
      winning_transaction = PlayerFaabTransaction.find_by(filter_params.merge(success: true, player_id: transaction.player_id))
        {
          user_id: transaction.user_id,
          year: transaction.season_year,
          week: transaction.week,
          player_id: transaction.player_id,
          amount: transaction.bid_amount,
          winning_amount: transaction.winning_bid,
          winning_user_id: winning_transaction.user_id,
          margin: transaction.winning_bid - transaction.bid_amount,
        }
    end
    calculated_stats.update(narrowest_fail: json)
  end

  def update_biggest_overpay(calculated_stats, filter_params)
    transactions = PlayerFaabTransaction.where(filter_params.merge(success: true)).all
    hashes = transactions.map do |transaction|
      next_highest_bid = PlayerFaabTransaction.where(filter_params.merge(success: false, player_id: transaction.player_id)).order(bid_amount: :desc).first
      {
        user_id: transaction.user_id,
        year: transaction.season_year,
        week: transaction.week,
        player_id: transaction.player_id,
        amount: transaction.bid_amount,
        next_highest_amount: next_highest_bid&.bid_amount || 0.0,
        next_highest_user_id: next_highest_bid&.user_id,
        overpay: transaction.bid_amount - (next_highest_bid&.bid_amount || 0.0),
      }
    end
    json = hashes.sort_by { |hash| -(hash[:amount] - hash[:next_highest_amount]) }.first(10)
    calculated_stats.update(biggest_overpay: json)
  end

  def update_most_impactful(calculated_stats, filter_params)
    transactions = PlayerFaabTransaction.where(filter_params.merge(success: true)).all
    hashes = transactions.map do |transaction|
      relevant_games = PlayerGame.where(
        player_id: transaction.player_id,
        user_id: transaction.user_id,
        game_id: Game.where(season_year: transaction.season_year).where('week >= ?', transaction.week).pluck(:id),
        active: true
      ).all
      points_scored = relevant_games.sum { |game| game.points || 0.0 }
      {
        user_id: transaction.user_id,
        year: transaction.season_year,
        week: transaction.week,
        player_id: transaction.player_id,
        amount: transaction.bid_amount,
        points_scored: points_scored.to_f.round(2),
      }
    end
    json = hashes.sort_by { |hash| -hash[:points_scored] }.first(10)
    calculated_stats.update(most_impactful: json)
  end

  def update_most_impactful_ppg(calculated_stats, filter_params)
    transactions = PlayerFaabTransaction.where(filter_params.merge(success: true)).all
    hashes = transactions.map do |transaction|
      relevant_games = PlayerGame.where(
        player_id: transaction.player_id,
        user_id: transaction.user_id,
        game_id: Game.where(season_year: transaction.season_year).where('week >= ?', transaction.week).pluck(:id),
        active: true
      ).all
      points_scored = relevant_games.sum { |game| game.points || 0.0 }
      actual_count = relevant_games.reduce(0) { |memo, game| game.game.playoff? ? memo + 2 : memo + 1 }
      {
        user_id: transaction.user_id,
        year: transaction.season_year,
        week: transaction.week,
        player_id: transaction.player_id,
        amount: transaction.bid_amount,
        ppg: (points_scored.to_f / ([actual_count, 1].max).to_f).round(2),
        games_played: actual_count,
      }
    end
    json = hashes.sort_by { |hash| -hash[:ppg] }.first(10)
    calculated_stats.update(most_impactful_ppg: json)
  end

  def update_most_impactful_ppd(calculated_stats, filter_params)
    transactions = PlayerFaabTransaction.where(filter_params.merge(success: true)).all
    hashes = transactions.map do |transaction|
      relevant_games = PlayerGame.where(
        player_id: transaction.player_id,
        user_id: transaction.user_id,
        game_id: Game.where(season_year: transaction.season_year).where('week >= ?', transaction.week).pluck(:id),
        active: true
      ).all
      points_scored = relevant_games.sum { |game| game.points || 0.0 }
      {
        user_id: transaction.user_id,
        year: transaction.season_year,
        week: transaction.week,
        player_id: transaction.player_id,
        amount: transaction.bid_amount,
        points_scored: points_scored,
        ppd: (points_scored.to_f / transaction.bid_amount.to_f).round(2),
      }
    end
    json = hashes.sort_by { |hash| -hash[:ppd] }.first(10)
    calculated_stats.update(most_impactful_ppd: json)
  end
end
