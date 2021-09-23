class BestBallGame < ApplicationRecord
  belongs_to :best_ball_league
  belongs_to :user
  has_many :best_ball_game_players, dependent: :destroy
  has_many :players, through: :best_ball_game_players

  def best_ball_league_user
    BestBallLeagueUser.find_by(best_ball_league: best_ball_league, user: user)
  end

  def lineup
    best_ball_game_players.starters.includes(:player).references(:player).map do |game_player|
      {
        name: game_player.player.name,
        position: game_player.position,
        points: game_player.total_points
      }.stringify_keys
    end
  end
end
