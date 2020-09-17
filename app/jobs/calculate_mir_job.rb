class CalculateMirJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
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
    calculated_stats = user.calculated_stats || UserStat.create(user_id: user.id)
    calculated_stats.update(mir: json_hash)
  end
end
