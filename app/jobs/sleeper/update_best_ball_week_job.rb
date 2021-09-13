module Sleeper
  class UpdateBestBallWeekJob < ApplicationJob
    def perform(league_id, week)
      league = BestBallLeague.find_by(sleeper_id: league_id)
      response = RestClient.get("https://api.sleeper.app/v1/league/#{league_id}/matchups/#{week}")
      parsed = JSON.parse(response.body)
      parsed.each do |object|
        league_user = league.best_ball_league_users.find_by(roster_id: object["roster_id"], )
        game = BestBallGame.find_or_create_by(week: week, best_ball_league: league, user: league_user.user)
        game.update(total_points: object["points"])
        BestBallGamePlayer.where(best_ball_game: game).update_all(starter: false)
        object["starters"].each_with_index do |player_id, index|
          player = Player.find_by(sleeper_id: player_id)
          game_player = BestBallGamePlayer.find_or_create_by(player: player, best_ball_game: game)
          game_player.update(total_points: object["starters_points"][index], starter: true)
        end
      end
    end
  end
end