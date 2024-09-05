class LoadHistoricalDraftsJob < ApplicationJob
  LEAGUE_MAPPING = {
    "2024":{
      drafted_league_platform: "sleeper",
      drafted_league_id: "1124845632452825088",
      league_platform: "espn",
      league_id: "209719"
    },
    "2023":{
      drafted_league_platform: "sleeper",
      drafted_league_id: "992181416802430976",
      league_platform: "espn",
      league_id: "209719"
    },
    "2022": {
      drafted_league_platform: "sleeper",
      drafted_league_id: "863913206069002240",
      league_platform: "espn",
      league_id: "209719"
    },
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
    },
    "2019": {
      drafted_league_platform: "sleeper",
      drafted_league_id: "469548369782501376",
      league_platform: "espn",
      league_id: "209719"
    },
    "2018": {
      drafted_league_platform: "espn",
      drafted_league_id: "209719",
      league_platform: "espn",
      league_id: "209719"
    },
    "2017": {
      drafted_league_platform: "espn",
      drafted_league_id: "209719",
      league_platform: "espn",
      league_id: "209719"
    },
    "2016": {
      drafted_league_platform: "espn",
      drafted_league_id: "209719",
      league_platform: "espn",
      league_id: "209719"
    },
    "2015": {
      drafted_league_platform: "espn",
      drafted_league_id: "209719",
      league_platform: "espn",
      league_id: "209719"
    }
  }.with_indifferent_access

  def perform
    LEAGUE_MAPPING.each do |season_year, draft_data|
      LoadDraftJob.perform_now(season_year, draft_data)
    end
  end
end