class BestBallGamePlayer < ApplicationRecord
  belongs_to :player
  belongs_to :best_ball_game

  POSITION_SORT = "CASE position WHEN 'QB' THEN 1 WHEN 'RB' THEN 2 WHEN 'WR' THEN 3 WHEN 'TE' THEN 4 "\
                  "WHEN 'FLEX' THEN 5 WHEN 'SUPER_FLEX' THEN 6 WHEN 'BN' THEN 7 END".freeze

  scope :lineup_ordered, -> { order(POSITION_SORT) }
end
