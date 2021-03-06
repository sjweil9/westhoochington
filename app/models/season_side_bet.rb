class SeasonSideBet < ApplicationRecord
  include SharedBetMethods

  belongs_to :user
  has_many :side_bet_acceptances, -> { where(bet_type: 'season') }, foreign_key: :side_bet_id

  before_validation :set_defaults
  after_create :update_calculated_stats

  validate :valid_winner, :valid_loser, :valid_status, :valid_odds, :valid_acceptances, :valid_bet_type,
           :valid_comparison_type, :valid_bet_terms
  validate :valid_closing_date, on: :create
  validates :amount, numericality: true
  validates :line, numericality: true

  VALID_BET_TYPES = {
    final_standings: 'Final Finish',
    total_points: 'Final Points',
    regular_season_finish: 'Regular Season Finish',
    regular_season_points: 'Regular Season Points'
  }

  VALID_BET_TYPES.keys.each do |type|
    define_method("#{type}?") { bet_type == type.to_s }
  end

  def regular_season?
    regular_season_finish? || regular_season_points?
  end

  def player_vs_field?
    comparison_type == '1VF'
  end

  def player_vs_player?
    comparison_type == '1V1'
  end

  def terms_description
    if player_vs_player?
      "#{winner_nickname}#{line_description} over #{loser_nickname}"
    else
      bet_terms['winner_id'] ? "#{winner_nickname}#{line_description} over The Field" : "The Field#{line_description} over #{loser_nickname}"
    end
  end

  def line_description
    return unless line.present? && !line.zero?

    line.positive? ? " (+#{line})" : " (#{line})"
  end

  def winner_nickname
    Rails.cache.fetch("nickname_#{bet_terms['winner_id']}")
  end

  def loser_nickname
    Rails.cache.fetch("nickname_#{bet_terms['loser_id']}")
  end

  def outcome_description
    "#{final_winner}: #{final_winning_result} to #{final_loser}: #{final_losing_result}"
  end

  def predictor_won?
    won
  end

  def finished?
    !won.nil?
  end

  private

  def final_winner
    return if won.nil?

    if player_vs_player?
      won ? winner_nickname : loser_nickname
    elsif bet_terms['winner_id']
      won ? winner_nickname : 'The Field'
    elsif bet_terms['loser_id']
      won ? 'The Field' : loser_nickname
    end
  end

  def final_loser
    return if won.nil?

    if player_vs_player?
      won ? loser_nickname : winner_nickname
    elsif bet_terms['winner_id']
      won ? 'The Field' : winner_nickname
    elsif bet_terms['loser_id']
      won ? loser_nickname : 'The Field'
    end
  end

  def final_winning_result
    won ? final_bet_results['bettor_value'] : final_bet_results['acceptor_value']
  end

  def final_losing_result
    won ? final_bet_results['acceptor_value'] : final_bet_results['bettor_value']
  end

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

  def valid_closing_date
    return if closing_date && closing_date.in_time_zone('America/Chicago') > Time.now.in_time_zone('America/Chicago')

    errors.add(:closing_date, "is invalid: must be a future date.")
  end
end
