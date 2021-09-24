class LoadHistoricalDraftsJob < ApplicationJob
  LEAGUE_MAPPING = {
    "2021": {
      drafted_league_platform: "sleeper",
      drafted_league_id: "737327330413969408",
      league_platform: "espn",
      league_id: "209719"
    },
    "2020": {
      drafted_league_platform: "espn",
      drafted_league_id: "209719",
      league_platform: "espn",
      league_id: "209719"
    }
  }

  def perform
    LEAGUE_MAPPING.each do |season_year, draft_data|
      LoadDraftJob.perform_now(season_year, draft_data)
    end
  end
end