class LoadWeeklyDataJob < ApplicationJob
  queue_as :default

  EMAIL_MAPPING = {
    '1':'ovaisinamullah@gmail.com',
    '2':'mikelacy3@gmail.com',
    '4':'tonypelli@gmail.com',
    '5':'goblue101@gmail.com',
    '6':'pkaushish@gmail.com',
    '7':'adamkos101@gmail.com',
    '8':'stephen.weil@gmail.com',
    '9':'captrf@gmail.com',
    '10':'seidmangar@gmail.com',
    '11':'mattforetich4@gmail.com'
  }.with_indifferent_access

  def perform(week)
    teams = EMAIL_MAPPING.keys.map(&:to_s).map(&:to_i)

    teams.each do |team|
      url = "#{base_url}&teamId=#{team}&matchupPeriodId=#{week}"

      response = RestClient.get(url)
      parsed_response = JSON.parse(response.body)

      team_data = parsed_response.dig('boxscore', 'teams').detect { |h| h['teamId'] == team }
      other_team_data = parsed_response.dig('boxscore', 'teams').detect { |h| h['teamId'] != team }
      game_data = {
        active_total: team_data['appliedActiveRealTotal'],
        bench_total: team_data['appliedInactiveRealTotal'],
        projected_total: team_data['appliedActiveProjectedTotal'],
        season_year: season_year,
        week: week,
        user_id: user_id_for(team),
        opponent_id: user_id_for(other_team_data['teamId']),
        opponent_active_total: other_team_data['appliedActiveRealTotal'],
        opponent_bench_total: other_team_data['appliedInactiveRealTotal'],
        opponent_projected_total: other_team_data['appliedActiveProjectedTotal'],
      }

      game = Game.find_by(
        week: week,
        season_year: season_year,
        user_id: user_id_for(team),
        opponent_id: user_id_for(other_team_data['teamId'])
      ) || Game.new

      game.update(game_data)
    end
  end

  private

  def base_url
    "http://games.espn.com/ffl/api/v2/boxscore?leagueId=209719&seasonId=#{season_year}"
  end

  def season_year
    Time.now.year
  end
  
  def user_id_for(team_id)
    @user_ids ||= {}
    @user_ids[team_id.to_s] ||= User.find_by(email: EMAIL_MAPPING[team_id.to_s]).id
  end
end



