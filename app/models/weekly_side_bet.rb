class WeeklySideBet < ApplicationRecord
  include SharedBetMethods

  has_many :side_bet_acceptances, -> { where(bet_type: "weekly") }, foreign_key: :side_bet_id
  belongs_to :user

  after_create :update_calculated_stats
  after_create :post_to_discord

  validate :valid_status, :valid_odds, :valid_acceptances, :validate_comparison_type!, :validate_bet_terms!,
           :validate_players!, :validate_week!
  validates :amount, numericality: true
  validates :line, numericality: true, allow_nil: true

  COMPARISON_TYPES = {
    pvp: %w[winner_id loser_id],
    high_score: %w[winner_id],
    over_under: %w[player_id line direction]
  }.with_indifferent_access

  BET_TYPE_DESCRIPTIONS = {
    pvp: "Player vs Player",
    high_score: "High Score",
    over_under: "Over/Under"
  }.with_indifferent_access

  COMPARISON_TYPES.keys.each do |key|
    define_method("#{key}?") { comparison_type == key }
  end

  def finished?
    Game.where(week: week, finished: true).count == 12
  end

  def terms_description
    if pvp?
      "#{winner_nickname} over #{loser_nickname}"
    elsif over_under?
      "#{player_nickname} #{over_under_direction} #{over_under_threshold} Points"
    elsif high_score?
      "#{winner_nickname} to get High Score"
    end
  end

  def outcome_description
    return over_under_outcome_description if over_under?

    "#{final_winner}: #{final_winning_result} to #{final_loser}: #{final_losing_result}"
  end

  def over_under_outcome_description
    "#{predicted_nickname} (#{final_value}) #{over_under_outcome_direction} #{over_under_threshold}"
  end

  private

  def predicted_nickname
    bet_terms['winner_id'] ? winner_nickname : loser_nickname
  end

  def final_value
    (final_standings? || regular_season_finish?) ? final_bet_results['bettor_value'].to_i.ordinalize : final_bet_results['bettor_value']
  end

  def over_under_outcome_direction
    won ? bet_terms['direction'] : %w[over under].detect { |val| val != bet_terms['over_under'] }
  end

  def over_under_threshold
    bet_terms["line"].to_f.round(2)
  end

  def validate_week!
    return if (1..13).include?(week.to_i)

    errors.add(:week, "must be between 1 and 13.")
  end

  def validate_comparison_type!
    return if valid_comparison_type?

    errors.add(:comparison_type, "is not valid.")
  end

  def valid_comparison_type?
    COMPARISON_TYPES.keys.include?(comparison_type)
  end

  def validate_bet_terms!
    return if valid_bet_terms?

    errors.add(:bet_terms, "do not match comparison type.")
  end

  def valid_bet_terms?
    COMPARISON_TYPES[comparison_type]&.all? { |key| bet_terms[key].present? } && (!over_under? || over_under_terms_valid?)
  end

  def over_under_terms_valid?
    %w[over under].include?(bet_terms["direction"])
  end

  def validate_players!
    return if valid_players?

    errors.add(:bet_terms, "Selected players are not valid.")
  end

  def valid_players?
    case comparison_type
    when "pvp" then valid_winner? && valid_loser? && different_players?
    when "high_score" then valid_winner?
    when "over_under" then valid_player?
    else true # comparison type isn't valid so don't give an error about players
    end
  end

  %w[loser winner player].each do |type|
    define_method("valid_#{type}?") do
      id_field = "#{type}_id"
      User.active.find(bet_terms[id_field]).present?
    end
  end

  def different_players?
    bet_terms["winner_id"] != bet_terms["loser_id"]
  end

  def post_to_discord
    Discord::Messages::WeeklySideBetJob.perform_now(self)
  end
end
