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

  end

  def retrieve_sleeper!
    draft = sleeper_client.league(drafted_league_id).drafts.first
    draft.draft_picks.each do |pick|

    end
  end
end