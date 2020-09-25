class SeasonSideBet < ApplicationRecord
  include SharedBetMethods

  belongs_to :user
  has_many :side_bet_acceptances, -> { where(bet_type: 'season') }, foreign_key: :side_bet_id

  before_validation :set_defaults

  validate :valid_winner, :valid_status, :valid_odds, :valid_acceptances
  validates :amount, numericality: true
  validates :line, numericality: true
end
