class SeasonSideBet < ApplicationRecord
  include SharedBetMethods

  belongs_to :user
  has_many :side_bet_acceptances, -> { where(bet_type: 'season') }, foreign_key: :side_bet_id

  before_validation :set_defaults

  validate :valid_winner, :valid_loser, :valid_status, :valid_odds, :valid_acceptances, :valid_bet_type,
           :valid_comparison_type, :valid_bet_terms
  validates :amount, numericality: true
  validates :line, numericality: true

  VALID_BET_TYPES = {
    final_standings: 'Final Finish',
    total_points: 'Final Points',
    regular_season_finish: 'Regular Season Finish',
    regular_season_points: 'Regular Season Points'
  }

  def player_vs_field?
    comparison_type == '1VF'
  end

  def player_vs_player?
    comparison_type == '1V1'
  end

  private

  VALID_COMPARISON_TYPES = %w[1VF 1V1]

  def valid_bet_type
    return if VALID_BET_TYPES.keys.include?(bet_type.to_sym)

    errors.add(:bet_type, "is invalid, must be one of: #{VALID_BET_TYPES.values.join(', ')}")
  end

  def valid_comparison_type
    return if VALID_COMPARISON_TYPES.include?(comparison_type)

    errors.add(:comparison_type, "is invalid, must be either Player vs Player or Player vs Field.")
  end

  def valid_bet_terms
    if player_vs_field?
      return if bet_terms && bet_terms.values_at('winner_id', 'loser_id').compact.size == 1

      errors.add(:bet_terms, "are invalid: if comparing against the field, you must select exactly one winner.")
    else
      return if bet_terms && bet_terms['winner_id'] && bet_terms['loser_id'] && bet_terms['winner_id'] != bet_terms['loser_id']

      errors.add(:bet_terms, "are invalid: if comparing between two players, two different players must be selected.")
    end
  end

  def valid_winner
    return if !bet_terms&.dig('winner_id') || User.pluck(:id).include?(bet_terms['winner_id'])

    errors.add(:winner, "is invalid: must be a valid registered player.")
  end

  def valid_loser
    return if !bet_terms&.dig('loser_id') || User.pluck(:id).include?(bet_terms['loser_id'])

    errors.add(:loser, "is invalid: must be a valid registered player.")
  end
end
