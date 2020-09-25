class SeasonSideBet < ApplicationRecord
  belongs_to :user
  has_many :side_bet_acceptances, -> { where(bet_type: 'season') }, foreign_key: :side_bet_id
end
