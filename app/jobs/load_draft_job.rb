class LoadDraftJob < ApplicationJob
  def perform(season_year, league_data)
    @season_year = season_year
    @league_data = league_data
    send("retrieve_#{drafted_league_platform}!")
  end

  private

  attr_reader :season_year, :league_data

  %w[drafted_league_id drafted_league_platform league_id league_platform].each do |method|
    define_method(method) { league_data[method] }
  end

  def retrieve_espn!
    picks = retrieve_espn_picks!
    picks.each do |pick|
      type = pick["bidAmount"].positive? ? "auction" : "snake"
      metadata = type == "auction" ? espn_auction_metadata(pick) : espn_snake_metadata(pick)
      email = EMAIL_MAPPING[season_year.to_s][pick["teamId"].to_s]
      user = User.find_by(email: email)
      player = Player.find_by(espn_id: pick["playerId"])
      pick_record = DraftPick.find_or_initialize_by(base_pick_params.merge(user: user, player: player, draft_type: type))
      pick_record.update!(metadata: metadata)
    end
  end

  def retrieve_sleeper!
    draft = sleeper_client.league(drafted_league_id).drafts.first
    draft.draft_picks.each do |pick|
      metadata = pick.auction? ? sleeper_auction_metadata(pick) : sleeper_snake_metadata(pick)
      user = User.find_by(sleeper_id: pick.picked_by)
      player = Player.find_by(sleeper_id: pick.player_id) || Player.find_by(name: [pick.metadata.first_name, pick.metadata.last_name].join(" "))
      pick_record = DraftPick.find_or_initialize_by(base_pick_params.merge(user: user, player: player, draft_type: pick.draft.type))
      pick_record.update!(metadata: metadata)
    end
  end

  def base_pick_params
    {
      season_year: season_year,
      league_platform: league_platform,
      league_id: league_id,
      drafted_league_platform: drafted_league_platform,
      drafted_league_id: drafted_league_id,
    }
  end

  def retrieve_espn_picks!
    if season_year.to_i < 2018
      resp = RestClient.get(espn_historical_url, cookies: espn_cookies)
      parsed = JSON.parse(resp.body)
      parsed[0]["draftDetail"]["picks"]
    else
      resp = RestClient.get(espn_url, cookies: espn_cookies)
      parsed = JSON.parse(resp.body)
      parsed["draftDetail"]["picks"]
    end
  end

  def sleeper_auction_metadata(pick)
    { bid_amount: pick.amount, overall_pick_number: pick.pick_no }
  end

  def sleeper_snake_metadata(pick)
    round_pick_number = pick.round.even? ? (pick.draft.teams - (pick.draft_slot - 1)) : pick.draft_slot
    { overall_pick_number: pick.pick_no, round_number: pick.round, round_pick_number: round_pick_number }
  end

  def espn_auction_metadata(pick)
    { bid_amount: pick["bidAmount"], overall_pick_number: pick["overallPickNumber"] }
  end

  def espn_snake_metadata(pick)
    { overall_pick_number: pick["overallPickNumber"], round_number: pick["roundId"], round_pick_number: pick["roundPickNumber"] }
  end

  def espn_url
    "https://fantasy.espn.com/apis/v3/games/ffl/seasons/#{season_year}/segments/0/leagues/209719?scoringPeriodId=0"\
    "&view=mDraftDetail&view=mStatus&view=mSettings&view=mTeam&view=mTransactions2&view=modular&view=mNav"
  end

  def espn_historical_url
    "https://fantasy.espn.com/apis/v3/games/ffl/leagueHistory/209719?scoringPeriodId=0&view=mDraftDetail"\
    "&view=mStatus&view=mSettings&view=mTeam&view=mTransactions2&view=modular&view=mNav"
  end
end