class GameSideBet < ApplicationRecord
  belongs_to :user
  has_many :side_bet_acceptances, -> { where(bet_type: 'game') }, foreign_key: :side_bet_id

  def game
    @game ||= Game.unscoped.find(game_id)
  end

  before_validation :set_defaults

  validate :valid_winner, :valid_status, :valid_odds, :valid_acceptances
  validates :amount, numericality: true
  validates :line, numericality: true

  def proposer_payout
    return amount unless odds.present?

    amount * odds.split(':').last.to_i
  end

  def acceptor_payout
    return amount unless odds.present?

    amount * odds.split(':').first.to_i
  end

  def acceptor_condition_string
    "#{Rails.cache.fetch("nickname_#{accepting_winner_id}")} #{acceptor_line_description}"
  end

  def proposer_condition_string
    "#{Rails.cache.fetch("nickname_#{predicted_winner_id}")} #{proposer_line_description}"
  end

  def terms_description
    str = Rails.cache.fetch("nickname_#{predicted_winner_id}")
    str += " (#{line})" if line.present? && !line.zero?
    str += " over #{Rails.cache.fetch("nickname_#{accepting_winner_id}")}"
    str
  end

  def valid_acceptor_ids
    if possible_acceptances&.dig('any')
      User.pluck(:id).reject
    else
      possible_acceptances&.dig('users').presence || []
    end
  end

  def maximum_acceptors
    possible_acceptances&.dig('max')
  end

  def update_winner
    winner_id = if line.present? && !line.zero?
                  predictor_score_base = game.user_id == predicted_winner_id ? game.active_total : game.opponent_active_total
                  acceptor_score_base = game.user_id == predicted_winner_id ? game.opponent_active_total : game.active_total
                  predictor_score_base + line > acceptor_score_base ? predicted_winner_id : accepting_winner_id
                end
    update(status: 'awaiting_payment', actual_winner_id: winner_id)
    side_bet_acceptances.update_all(status: 'awaiting_payment')
  end

  def predictor_won?
    predicted_winner_id == actual_winner_id
  end

  def acceptor_won?
    predicted_winner_id != actual_winner_id && actual_winner_id.present?
  end

  private

  def acceptor_line_description
    return 'wins' unless line.present? && !line.zero?

    if line.positive?
      "wins by more than #{line} points"
    else
      "wins, ties, or loses by no more than #{line} points"
    end
  end

  def proposer_line_description
    return 'wins' unless line.present? && !line.zero?

    if line.positive?
      "wins, ties, or loses by no more than #{line} points"
    else
      "wins by more than #{line} points"
    end
  end

  def accepting_winner_id
    [game.user_id, game.opponent_id].reject { |id| id == predicted_winner_id }.first
  end

  BET_STATUSES = %w[awaiting_bets awaiting_resolution awaiting_payment awaiting_confirmation completed]

  BET_STATUSES.each do |status|
    define_method("#{status}?") { self.status == status }
  end

  def set_defaults
    self.status ||= 'awaiting_bets'
  end

  def valid_winner
    return if [game.user_id, game.opponent_id].include?(predicted_winner_id)

    errors.add(:predicted_winner_id, "was somehow not one of the two involved players; either you're trying some whack shit, or this shit is fucked up, so let me know if it's the latter.")
  end

  def valid_status
    return if BET_STATUSES.include?(status)

    errors.add(:status, "must be one of #{BET_STATUSES.join(', ')}")
  end

  def valid_odds
    return if odds =~ /\A\d+:\d+\Z/

    errors.add(:odds, "must be a valid string in the form of {number}:{number}")
  end

  def valid_acceptances
    return if valid_acceptances?

    errors.add(:possible_acceptances, "must be either a numeric limit or a list of valid players.")
  end

  def valid_acceptances?
    possible_acceptances.is_a?(Hash) &&
      [true, false].include?(possible_acceptances['any']) &&
      (possible_acceptances['users'].nil? || possible_acceptances['users'].is_a?(Array)) &&
      (!possible_acceptances['max'] || possible_acceptances['max'].is_a?(Integer))
  end
end
