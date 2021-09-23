class BestBallLeague < ApplicationRecord
  has_many :best_ball_league_users
  has_many :users, through: :best_ball_league_users
  has_many :best_ball_games
end
