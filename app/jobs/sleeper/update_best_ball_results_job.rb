module Sleeper
  class UpdateBestBallResultsJob < ApplicationJob
    def perform(league_id)
      response = RestClient.get("https://api.sleeper.app/v1/league/#{league_id}/rosters")
      parsed = JSON.parse(response.body)
      league = BestBallLeague.find_by(sleeper_id: league_id)
      parsed.each do |object|
        user = User.find_by(sleeper_id: object["owner_id"])
        league_user = BestBallLeagueUser.find_or_create_by(best_ball_league: league, user: user)
        league_user.update(roster_id: object["roster_id"], total_points: object.dig("settings", "fpts"))
      end
    end
  end
end