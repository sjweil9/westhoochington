class BestBallGame < ApplicationRecord
  belongs_to :best_ball_league
  belongs_to :user
end
