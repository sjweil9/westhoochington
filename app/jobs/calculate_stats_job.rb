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
        memo.merge(user.id.to_s => {
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
end
