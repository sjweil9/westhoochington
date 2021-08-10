class SeasonSideBet < ApplicationRecord
  include SharedBetMethods

  belongs_to :user
  has_many :side_bet_acceptances, -> { where(bet_type: 'season') }, foreign_key: :side_bet_id

  before_validation :set_defaults
  after_create :update_calculated_stats
  after_create :post_to_discord

  validate :valid_winner, :valid_loser, :valid_status, :valid_odds, :valid_acceptances, :valid_bet_type,
           :valid_comparison_type, :valid_bet_terms
  validate :valid_closing_date, on: :create
  validates :amount, numericality: true
  validates :line, numericality: true, allow_nil: true

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
    comparison_type == '1VF'.freeze
  end

  def player_vs_player?
    comparison_type == '1V1'.freeze
  end

  def over_under?
    comparison_type == 'OU'.freeze
  end

  def terms_description
    if player_vs_player?
      "#{winner_nickname}#{line_description} over #{loser_nickname}"
    elsif over_under?
      "#{winner_nickname} #{over_under_direction} #{over_under_threshold}"
    else
      bet_terms['winner_id'] ? "#{winner_nickname}#{line_description} over The Field" : "The Field#{line_description} over #{loser_nickname}"
    end
  end

  def line_description
    return unless line.present? && !line.zero?

    line.positive? ? " (+#{line})" : " (#{line})"
  end

  def winner_nickname
    Rails.cache.fetch("nickname_#{bet_terms['winner_id']}") { User.find(bet_terms["winner_id"]).random_nickname }
  end

  def loser_nickname
    Rails.cache.fetch("nickname_#{bet_terms['loser_id']}") { User.find(bet_terms["loser_id"]).random_nickname }
  end

  def outcome_description
    return over_under_outcome_description if over_under?

    "#{final_winner}: #{final_winning_result} to #{final_loser}: #{final_losing_result}"
  end

  def predictor_won?
    won
  end

  def finished?
    !won.nil?
  end

  def over?
    bet_terms['over_under'] == 'over'
  end

  def under?
    bet_terms['over_under'] == 'under'
  end

  private

  def over_under_direction
    bet_terms['over_under']&.downcase
  end

  def over_under_threshold
    (final_standings? || regular_season_finish?) ? "#{bet_terms['threshold'].to_i.ordinalize} Place" : "#{bet_terms['threshold']} Points"
  end

  def over_under_outcome_description
    "#{predicted_nickname} (#{final_value}) #{over_under_outcome_direction} #{over_under_threshold}"
  end

  def predicted_nickname
    bet_terms['winner_id'] ? winner_nickname : loser_nickname
  end

  def final_value
    (final_standings? || regular_season_finish?) ? final_bet_results['bettor_value'].to_i.ordinalize : final_bet_results['bettor_value']
  end

  def over_under_outcome_direction
    won ? bet_terms['over_under'] : %w[over under].detect { |val| val != bet_terms['over_under'] }
  end

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
      won ? loser_description : winner_nickname
    elsif bet_terms['loser_id']
      won ? loser_nickname : winner_description
    end
  end

  def loser_description
    over_under? ? 'Under' : 'The Field'
  end

  def winner_description
    over_under? ? 'Over' : 'The Field'
  end

  def final_winning_result
    won ? final_bet_results['bettor_value'] : final_bet_results['acceptor_value']
  end

  def final_losing_result
    won ? final_bet_results['acceptor_value'] : final_bet_results['bettor_value']
  end

  VALID_COMPARISON_TYPES = %w[1VF 1V1 OU]

  def valid_bet_type
    return if VALID_BET_TYPES.keys.include?(bet_type.to_sym)

    errors.add(:bet_type, "is invalid, must be one of: #{VALID_BET_TYPES.values.join(', ')}")
  end

  def valid_comparison_type
    return if VALID_COMPARISON_TYPES.include?(comparison_type)

    errors.add(:comparison_type, "is invalid, must be either Player vs Player or Player vs Field.")
  end

  def valid_bet_terms
    if player_vs_field? || over_under?
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

  def post_to_discord
    Discord::Messages::SeasonSideBetJob.perform_now(self)
  end
end
