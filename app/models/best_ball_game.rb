class BestBallGame < ApplicationRecord
  belongs_to :best_ball_league
  belongs_to :user
  has_many :best_ball_game_players, dependent: :destroy
  has_many :players, through: :best_ball_game_players

  def best_ball_league_user
    BestBallLeagueUser.find_by(best_ball_league: best_ball_league, user: user)
  end
end
