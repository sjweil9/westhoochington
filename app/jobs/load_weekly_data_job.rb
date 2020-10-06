require 'csv'

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
      '11': 'sccrrckstr@gmail.com'
    },
    '2020': {
      '1': 'ovaisinamullah@gmail.com',
      '2': 'mikelacy3@gmail.com',
      '4': 'tonypelli@gmail.com',
      '5': 'goblue101@gmail.com',
      '6': 'pkaushish@gmail.com',
      '7': 'adamkos101@gmail.com',
      '8': 'stephen.weil@gmail.com',
      '9': 'captrf@gmail.com',
      '10': 'seidmangar@gmail.com',
      '11': 'sccrrckstr@gmail.com'
    }
  }.with_indifferent_access

  def perform(week, year, skip_calculated_stats: false)
    @year = year.to_s
    teams = EMAIL_MAPPING[@year].keys.map(&:to_s).map(&:to_i)

    url = "#{base_url}&scoringPeriodId=#{week}"

    puts "Loading data for week #{week}, #{year}"

    response = RestClient.get(url, cookies: cookies)
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
        active_total: team_data.dig('rosterForCurrentScoringPeriod', 'appliedStatTotal') || 0.0,
        bench_total: bench_total(team_players) || 0.0,
        projected_total: projected_total(team_players) || 0.0,
        season_year: @year.to_i,
        week: week,
        user_id: user_id_for(team),
        opponent_id: user_id_for(other_team_data['teamId']),
        opponent_active_total: other_team_data.dig('rosterForCurrentScoringPeriod', 'appliedStatTotal') || 0.0,
        opponent_bench_total: bench_total(other_team_players) || 0.0,
        opponent_projected_total: projected_total(other_team_players) || 0.0,
        started: lineup_locked?([*team_players, *other_team_players]),
        finished: game_data['winner'] != 'UNDECIDED',
      }

      game = Game.unscoped.find_by(
        week: [14, 16].include?(week) ? week - 1 : week,
        season_year: @year.to_i,
        user_id: user_id_for(team),
        opponent_id: user_id_for(other_team_data['teamId'])
      )

      if [14, 16].include?(week) && game
        game.active_total += game_data[:active_total]
        game.bench_total += game_data[:bench_total]
        game.projected_total += game_data[:projected_total]
        game.opponent_active_total += game_data[:opponent_active_total]
        game.opponent_bench_total += game_data[:opponent_bench_total]
        game.opponent_projected_total += game_data[:opponent_projected_total]
        game.save
        next
      end

      game ||= Game.new

      game.update(game_data)

      # only load player stats if game ended
      next unless game_data['winner'] != 'UNDECIDED'

      team_players.each do |player|
        player_id = player['playerId']
        player_name = player.dig('playerPoolEntry', 'player', 'fullName')
        player_record = Player.find_by(espn_id: player_id)
        player_record ||= Player.new
        player_record.update(espn_id: player_id, name: player_name)

        user_id = user_id_for(team)
        game_id = Game.find_by(season_year: year, week: week, user_id: user_id)&.id
        actual_points = player.dig('playerPoolEntry', 'player', 'stats').detect { |stat| stat['statSourceId'].zero? }&.dig('appliedTotal')
        projected_points = player.dig('playerPoolEntry', 'player', 'stats').detect { |stat| stat['statSourceId'] == 1 }&.dig('appliedTotal')
        player_game_data = {
          player_id: player_record.id,
          user_id: user_id,
          game_id: game_id,
          points: actual_points || 0.0,
          projected_points: projected_points || 0.0,
          active: ACTIVE_PLAYER_SLOTS.include?(player['lineupSlotId']),
          lineup_slot: ROSTER_SLOT_MAPPING[player['lineupSlotId'].to_s],
          default_lineup_slot: POSITION_ID_MAPPING[player.dig('playerPoolEntry', 'player', 'defaultPositionId').to_s],
        }
        player_game = PlayerGame.find_by(player_id: player_record.id, user_id: user_id, game_id: game_id)
        player_game ||= PlayerGame.new
        player_game.update(player_game_data)
      end
    end

    return if skip_calculated_stats

    User.all.each do |user|
      CalculateStatsJob.new.perform(user.id)
      CalculateStatsJob.new.perform_year(user.id, @year.to_i)
    end

    CalculateStatsJob.new.perform_game_level
  end

  # DO NOT USE BELOW, HARD TO KNOW IF ACTIVE OR NOT, USE WEEKLY DATA LOAD
  def perform_player_data(year, week)
    url = "https://fantasy.espn.com/apis/v3/games/ffl/seasons/#{year}/segments/0/leagues/209719?view=kona_playercard&scoringPeriodId=#{week}"
    headers = {"X-Fantasy-Filter"=>"{\"players\":{\"filterActive\":{\"value\":true}}}"}
    response = RestClient.get(url, headers.merge(cookies: cookies))
    players = JSON.parse(response.body)['players']
    players.each do |player|
      id = player['id']
      name = player.dig('player', 'fullName')
      player_record = Player.find_by(espn_id: id)
      player_record ||= Player.new
      player_record.update(espn_id: id, name: name)

      # FA
      next if player['onTeamId'].zero?

      # statSourceId == 1 means projection, 0 is actual
      player_game = player.dig('player', 'stats').detect { |stat| stat['seasonId'] == year && stat['scoringPeriodId'] == week && stat['statSourceId'].zero? }
      next unless player_game.present?

      user_id = User.find_by(espn_id: player['onTeamId']).id
      game_id = Game.find_by(season_year: year, week: week, user_id: user_id).id
      player_game_data = {
        player_id: player_record.id,
        user_id: user_id,
        game_id: game_id,
        points: player_game['appliedTotal'],
        active: player.dig('player', 'active'),
      }
      player_game = PlayerGame.find_by(player_id: player_record.id, user_id: user_id, game_id: game_id)
      player_game ||= PlayerGame.new
      player_game.update(player_game_data)
    end
  end

  def perform_transaction_data(year, week)
    url = "https://fantasy.espn.com/apis/v3/games/ffl/seasons/#{year}/segments/0/leagues/209719?scoringPeriodId=#{week}&view=mDraftDetail&view=mStatus&view=mSettings&view=mTeam&view=mTransactions2&view=modular&view=mNav"
    response = RestClient.get(url, cookies: cookies)
    transactions = JSON.parse(response.body)['transactions']

    waiver_moves = transactions.select { |trans| trans['type'] == 'WAIVER' }
    waiver_moves.each do |move|
      next unless %w[FAILED_INVALIDPLAYERSOURCE EXECUTED].include?(move['status'])

      successful_bid = move['status'] == 'EXECUTED' ?
                         move :
                         waiver_moves.detect { |mv| mv['status'] == 'EXECUTED' && mv.dig('items', 0, 'playerId') == move.dig('items', 0, 'playerId') }

      # if player submitted multiple attempts to get same player (eg dropping diff players), not counting those as failures
      next if successful_bid != move && successful_bid['teamId'] == move['teamId']

      espn_player_id, team_id = move['items'].detect { |item| item['type'] == 'ADD' }.values_at('playerId', 'toTeamId')
      player_id = Player.find_by(espn_id: espn_player_id).id
      user_id = User.find_by(espn_id: team_id).id
      transaction_data = {
        player_id: player_id,
        user_id: user_id,
        success: move['status'] == 'EXECUTED',
        season_year: year,
        week: week,
        bid_amount: move['bidAmount'],
        winning_bid: successful_bid['bidAmount'],
      }

      transaction = PlayerFaabTransaction.find_by(player_id: player_id, user_id: user_id, season_year: year, week: week)
      transaction ||= PlayerFaabTransaction.new
      transaction.update(transaction_data)
    end
  end

  def perform_historical(year)
    # make sure you don't accidentally run this for more recent years that have better data
    return if year.to_i >= 2018

    @year = year.to_s
    url = base_historical_url + "&seasonId=#{year}"
    (1..15).each do |week|
      headers = {"X-Fantasy-Filter"=>"{\"schedule\":{\"filterMatchupPeriodIds\":{\"value\":[#{week}]}}}"}
      response = RestClient.get(url + "&scoringPeriodId=#{week}", headers.merge(cookies: cookies))
      parsed_response = JSON.parse(response.body).first

      data_for_week = parsed_response['schedule']
      teams = EMAIL_MAPPING[@year].keys.map(&:to_s).map(&:to_i)
      teams.each do |team|
        game_data = data_for_week.detect { |game| game.dig('away', 'teamId') == team || game.dig('home', 'teamId') == team }

        next unless game_data

        team_data = game_data.dig('away', 'teamId') == team ? game_data['away'] : game_data['home']
        other_team_data = game_data.dig('away', 'teamId') == team ? game_data['home'] : game_data['away']
        team_players = team_data.dig('rosterForMatchupPeriod', 'entries')
        other_team_players = other_team_data.dig('rosterForMatchupPeriod', 'entries')
        game_data = {
          active_total: team_data.dig('rosterForMatchupPeriod', 'appliedStatTotal') || team_data['totalPoints'],
          bench_total: bench_total(team_players),
          season_year: @year.to_i,
          week: week,
          user_id: user_id_for(team),
          opponent_id: user_id_for(other_team_data['teamId']),
          opponent_active_total: other_team_data.dig('rosterForMatchupPeriod', 'appliedStatTotal') || other_team_data['totalPoints'],
          opponent_bench_total: bench_total(other_team_players),
          started: true,
          finished: true,
        }

        game = Game.find_by(
          week: week,
          season_year: @year.to_i,
          user_id: user_id_for(team),
          opponent_id: user_id_for(other_team_data['teamId'])
        )
        game ||= Game.new

        game.update(game_data)

        binding.pry if team_players.nil?
        team_players.each do |player|
          player_id = player['playerId']
          player_name = player.dig('playerPoolEntry', 'player', 'fullName')
          player_record = Player.find_by(espn_id: player_id)
          player_record ||= Player.new
          player_record.update(espn_id: player_id, name: player_name)

          user_id = user_id_for(team)
          game_id = game.id
          actual_points = player.dig('playerPoolEntry', 'appliedStatTotal')
          player_game_data = {
            player_id: player_record.id,
            user_id: user_id,
            game_id: game_id,
            points: actual_points || 0.0,
            active: true,
            lineup_slot: POSITION_ID_MAPPING[player.dig('playerPoolEntry', 'player', 'defaultPositionId').to_s],
            default_lineup_slot: POSITION_ID_MAPPING[player.dig('playerPoolEntry', 'player', 'defaultPositionId').to_s],
          }
          player_game = PlayerGame.find_by(player_id: player_record.id, user_id: user_id, game_id: game_id)
          player_game ||= PlayerGame.new
          player_game.update(player_game_data)
        end
      end
    end

    general_response = RestClient.get(url, cookies: cookies)
    parsed_response = JSON.parse(general_response.body).first

    user_results = parsed_response['teams']

    user_results.each do |result|
      season_data = {
        user_id: user_id_for(result['id']),
        regular_rank: result['playoffSeed'],
        playoff_rank: result['rankCalculatedFinal'],
        season_year: @year.to_i,
      }

      user_season = Season.find_by(season_year: @year.to_i, user_id: user_id_for(result['id'])) || Season.new
      user_season.update(season_data)
    end
  end

  def perform_season_data(year, url = nil, retries = 0)
    return if retries > 1

    @year = year.to_s
    url ||= base_historical_url + "&seasonId=#{year}"

    response = RestClient.get(url, cookies: cookies)
    # when you retry with the override URL, its got the same data structure as the other URL, but it's no longer an array, because... reasons?
    retries.positive? ? parsed_response = JSON.parse(response.body) : parsed_response = JSON.parse(response.body).first

    user_results = parsed_response['teams']

    user_results.each do |result|
      season_data = {
        user_id: user_id_for(result['id']),
        regular_rank: result['playoffSeed'],
        playoff_rank: result['rankCalculatedFinal'],
        season_year: @year.to_i,
      }

      user_season = Season.find_by(season_year: @year.to_i, user_id: user_id_for(result['id'])) || Season.new
      user_season.update(season_data)
    end
  rescue RestClient::ExceptionWithResponse => e
    # usually this is 404 if you are trying to run for the most recent season, so try and fallback to that one
    override_url = "https://fantasy.espn.com/apis/v3/games/ffl/seasons/#{year}/segments/0/leagues/209719?view=modular&view=mNav&view=mMatchupScore&view=mScoreboard&view=mStatus&view=mSettings&view=mTeam&view=mPendingTransactions"
    perform_season_data(year, override_url, retries + 1)
  end

  def perform_csv(yahoo: false)
    csv = Rails.root.join('lib', 'assets', yahoo ? 'yahoo.csv' : 'backup.csv')
    CSV.foreach(csv) do |row|
      season_year, week, user_email, opp_email, active_points, bench_points, projected_points, opp_active_points, opp_bench_points, opp_projected_points = row
      next unless season_year.to_i.to_s == season_year.to_s

      @year = season_year
      week = 14 if week.to_i == 13 && @year.to_i >= 2018
      week = 16 if week.to_i == 15 && @year.to_i >= 2018

      game_data = {
        active_total: active_points,
        season_year: season_year,
        week: week,
        user_id: user_by_email(user_email),
        opponent_id: user_by_email(opp_email),
        bench_total: bench_points,
        projected_total: projected_points,
        opponent_active_total: opp_active_points,
        opponent_bench_total: opp_bench_points,
        opponent_projected_total: opp_projected_points,
      }

      game_to_create = Game.find_by(
        week: week,
        season_year: season_year,
        user_id: user_by_email(user_email),
        opponent_id: user_by_email(opp_email)
      )

      if [14, 16].include?(week.to_i) && game_to_create && @year.to_i >= 2018
        game_to_create.active_total += game_data[:active_total].to_f
        game_to_create.bench_total += game_data[:bench_total].to_f
        game_to_create.projected_total += game_data[:projected_total].to_f
        game_to_create.opponent_active_total += game_data[:opponent_active_total].to_f
        game_to_create.opponent_bench_total += game_data[:opponent_bench_total].to_f
        game_to_create.opponent_projected_total += game_data[:opponent_projected_total].to_f
        game_to_create.save
        next
      end

      game_to_create ||= Game.new

      game_to_create.update(game_data)
    end
  end

  def perform_yahoo_seasons
    csv = Rails.root.join('lib', 'assets', 'yahoo_seasons.csv')
    CSV.foreach(csv) do |row|
      year, user, playoff_rank, regular_rank = row
      next unless year.to_i.to_s == year.to_s

      @year = year
      season = Season.find_by(user_id: user_by_email(user), season_year: year) || Season.new
      season_data = {
        season_year: year,
        user_id: user_by_email(user),
        playoff_rank: playoff_rank,
        regular_rank: regular_rank,
      }
      season.update(season_data)
    end
  end

  private

  def cookies
    { SWID:"{#{Rails.application.credentials.espn_swid}}", espn_s2:Rails.application.credentials.espn_s2 }
  end

  ROSTER_SLOT_MAPPING = {
    '20': 'BN',
    '2': 'RB',
    '4': 'WR',
    '17': 'K',
    '0': 'QB',
    '23': 'FLEX',
    '6': 'TE',
    '16': 'DST',
    '21': 'IR',
  }.with_indifferent_access

  POSITION_ID_MAPPING = {
    '1': 'QB',
    '2': 'RB',
    '5': 'K',
    '3': 'WR',
    '4': 'TE',
    '16': 'DST'
  }.with_indifferent_access

  ACTIVE_PLAYER_SLOTS = [2, 4, 17, 0, 23, 6, 16]

  PROJECTED_ID = 1

  ACTUAL_ID = 0

  def bench_total(players)
    players&.reduce(0) do |total, player|
      if player['lineupSlotId'] == 20
        total + player.dig('playerPoolEntry', 'appliedStatTotal')
      else
        total + 0
      end
    end
  end

  def projected_total(players)
    players&.reduce(0) do |total, player|
      if ACTIVE_PLAYER_SLOTS.include?(player['lineupSlotId'])
        projected_stat_entry = player.dig('playerPoolEntry', 'player', 'stats').detect { |stat| stat['statSourceId'] == PROJECTED_ID }
        total + (projected_stat_entry&.dig('appliedTotal') || 0)
      else
        total + 0
      end
    end
  end

  def lineup_locked?(players)
    players.any? do |player|
      ACTIVE_PLAYER_SLOTS.include?(player['lineupSlotId']) && player.dig('playerPoolEntry', 'lineupLocked')
    end
  end

  def base_url
    "http://fantasy.espn.com/apis/v3/games/ffl/seasons/#{@year}/segments/0/leagues/209719?view=mMatchup&view=mMatchupScore"
  end

  def base_historical_url
    "https://fantasy.espn.com/apis/v3/games/ffl/leagueHistory/209719?view=modular&view=mNav&view=mMatchupScore&view=mScoreboard&view=mSettings&view=mTopPerformers&view=mTeam"
  end
  
  def user_id_for(team_id)
    @user_ids ||= {}
    @user_ids[team_id.to_s] ||= User.find_by(email: EMAIL_MAPPING[@year][team_id.to_s])&.id
  end

  def user_by_email(email)
    @user_ids ||= {}
    @user_ids[email] ||= User.find_by(email: email)&.id
  end

  def matchup_period_for_week(week)
    return week if week < 13
    return 14 if [15, 16].include?(week)

    13 if [13, 14].include?(week)
  end
end



