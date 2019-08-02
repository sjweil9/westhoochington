class LoadWeeklyDataJob < ApplicationJob
  queue_as :default

  # fantasy.espn.com/apis/v3/games/ffl/seasons/2018/segments/0/leagues/209719?view=mMatchup&view=mMatchupScore&scoringPeriodId=1
  # 'schedule' contains all the games, only the ones with the correct matchupPeriodId have the complete detail
  # for those, 'away' and 'home' break up teams, pointsByScoringPeriod gives breakdown (for playoff weeks), teamId gives team,
  # rosterForCurrentScoringPeriod has the estimates, inside 'entries' is players, each has:
  # name: playerPoolEntry.player.fullName
  # injured: playerPoolEntry.player.injured / .injuryStatus
  # active: playerPoolEntry.player.active
  # position: playerPoolEntry.player.defaultPositionId (2 =RB)
  # stats: playerPoolEntry.player.stats is an array, the element with statSourceId == 0 is actual, statSourceId == 1 is projected
  # for playoff matchups, there are more than just two of these elements, but they also have scoringPeriodId

  EMAIL_MAPPING = {
    '2015': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'brandon.tricou@gmail.com',
      '3': 'stewart.hackler@gmail.com',
      '4': 'sccrrckstr@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'john.rosensweig@gmail.com',
      '7': 'jstatham3@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com'
    },
    '2016': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'brandon.tricou@gmail.com',
      '3': 'stewart.hackler@gmail.com',
      '4': 'sccrrckstr@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'john.rosensweig@gmail.com',
      '7': 'jstatham3@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com'
    },
    '2017': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '3': 'stewart.hackler@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com'
    },
    '2018': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'mattforetich4@gmail.com'
    },
    '2019': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '12': 'sccrrckstr@gmail.com'
    }
  }.with_indifferent_access

  def perform(week, year)
    @year = year.to_s
    teams = EMAIL_MAPPING[@year].keys.map(&:to_s).map(&:to_i)

    url = "#{base_url}&scoringPeriodId=#{week}"

    puts "Loading data for week #{week}"

    response = RestClient.get(url, cookies: {SWID:"{3D566DFD-0281-4080-BC8C-6040AC2111D6}", espn_s2:"AECtxdpKxtPgixpViyPWhHzNEH2wH4JjqG2yiVqFF%2FZiRBbMVpbvvFxoFLNjkXOfba0JXYYhPpA17pu09eNOKgndykM0w0wEFFpjkK13DV73JjT3z6tA%2Bg8%2Bj%2FoknX0CdSoqox4fEaygdWX85atWUWVcSlQ7B2nQSx4iHqKUcDgRjhjJ9CQJtgUEry3JaId6o9aXo7ugfc6TOmuOK7N3JKh9%2FkWTKYba7xVXZ4MK7HjXNdjm66o4pAd4iDx7b9%2BMYDWqdDox6%2BOT8k%2BzOLh0W8eW"})
    parsed_response = JSON.parse(response.body)
    matchup_period = matchup_period_for_week(week.to_i)
    data_for_week = parsed_response.dig('schedule').select { |game| game['matchupPeriodId'].to_i == matchup_period }


    teams.each do |team|
      game_data = data_for_week.detect { |game| game.dig('away', 'teamId') == team || game.dig('home', 'teamId') == team }

      next unless game_data

      team_data = game_data.dig('away', 'teamId') == team ? game_data['away'] : game_data['home']
      other_team_data = game_data.dig('away', 'teamId') == team ? game_data['home'] : game_data['away']
      team_players = team_data.dig('rosterForCurrentScoringPeriod', 'entries')
      other_team_players = other_team_data.dig('rosterForCurrentScoringPeriod', 'entries')
      game_data = {
        active_total: team_data.dig('rosterForCurrentScoringPeriod', 'appliedStatTotal'),
        bench_total: bench_total(team_players),
        projected_total: projected_total(team_players),
        season_year: @year.to_i,
        week: week,
        user_id: user_id_for(team),
        opponent_id: user_id_for(other_team_data['teamId']),
        opponent_active_total: other_team_data.dig('rosterForCurrentScoringPeriod', 'appliedStatTotal'),
        opponent_bench_total: bench_total(other_team_players),
        opponent_projected_total: projected_total(other_team_players),
      }

      game = Game.find_by(
        week: week,
        season_year: @year.to_i,
        user_id: user_id_for(team),
        opponent_id: user_id_for(other_team_data['teamId'])
      ) || Game.new

      game.update(game_data)
    end
  end

  def perform_historical(year)
    @year = year.to_s
    url = base_historical_url + "&seasonId=#{year}"

    response = RestClient.get(url, cookies: {SWID:"{#{Rails.application.credentials.espn_swid}}", espn_s2:Rails.application.credentials.espn_s2})
    parsed_response = JSON.parse(response.body).first

    games = parsed_response['schedule']

    games.each do |game|
      %w[home away].each do |side|
        other_side = side == 'home' ? 'away' : 'home'
        game_data = {
          active_total: game.dig(side, 'totalPoints'),
          season_year: @year.to_i,
          week: game['matchupPeriodId'],
          user_id: user_id_for(game.dig(side, 'teamId')),
          opponent_id: user_id_for(game.dig(other_side, 'teamId')),
          opponent_active_total: game.dig(other_side, 'totalPoints'),
        }

        game_to_create = Game.find_by(
          week: game['matchupPeriodId'],
          season_year: @year.to_i,
          user_id: user_id_for(game.dig(side, 'teamId')),
          opponent_id: user_id_for(game.dig(other_side, 'teamId'))
        ) || Game.new

        game_to_create.update(game_data)
      end
    end
  end

  private

  ROSTER_SLOT_MAPPING = {
    '20': 'BENCH',
    '2': 'RB',
    '4': 'WR',
    '17': 'K',
    '0': 'QB',
    '23': 'FLEX',
    '6': 'TE',
    '16': 'DST',
  }.with_indifferent_access

  ACTIVE_PLAYER_SLOTS = [2, 4, 17, 0, 23, 6, 16]

  PROJECTED_ID = 1

  ACTUAL_ID = 0

  def bench_total(players)
    players.reduce(0) do |total, player|
      if player['lineupSlotId'] == 20
        total + player.dig('playerPoolEntry', 'appliedStatTotal')
      else
        total + 0
      end
    end
  end

  def projected_total(players)
    players.reduce(0) do |total, player|
      if ACTIVE_PLAYER_SLOTS.include?(player['lineupSlotId'])
        projected_stat_entry = player.dig('playerPoolEntry', 'player', 'stats').detect { |stat| stat['statSourceId'] == PROJECTED_ID }
        total + (projected_stat_entry&.dig('appliedTotal') || 0)
      else
        total + 0
      end
    end
  end

  def base_url
    "http://fantasy.espn.com/apis/v3/games/ffl/seasons/#{@year}/segments/0/leagues/209719?view=mMatchup&view=mMatchupScore"
  end

  def base_historical_url
    "https://fantasy.espn.com/apis/v3/games/ffl/leagueHistory/209719?view=mMatchupScore&view=mRoster&view=mScoreboard&view=mSettings&view=mTopPerformers&view=mTeam&view=modular&view=mNav"
  end
  
  def user_id_for(team_id)
    @user_ids ||= {}
    @user_ids[team_id.to_s] ||= User.find_by(email: EMAIL_MAPPING[@year][team_id.to_s])&.id
  end

  def matchup_period_for_week(week)
    return week if week < 13
    return 14 if [15, 16].include?(week)

    13 if [13, 14].include?(week)
  end
end



