class GameSideBet < ApplicationRecord
  include SharedBetMethods

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
    str += " (#{line.positive? ? '+' + line.to_s : line})" if line.present? && !line.zero?
    str += " over #{Rails.cache.fetch("nickname_#{accepting_winner_id}")}"
    str
  end

  def valid_acceptor_ids
    possible_acceptances&.dig('users').presence || User.pluck(:id)
  end

  def maximum_acceptors
    possible_acceptances&.dig('max')
  end

  def game_finished!
    winner_id = if line.present? && !line.zero?
                  predictor_score_base = game.user_id == predicted_winner_id ? game.active_total : game.opponent_active_total
                  acceptor_score_base = game.user_id == predicted_winner_id ? game.opponent_active_total : game.active_total
                  predictor_score_base + line > acceptor_score_base ? predicted_winner_id : accepting_winner_id
                end
    update(status: 'awaiting_payment', actual_winner_id: winner_id)
    side_bet_acceptances.update_all(status: 'awaiting_payment')
  end

  def game_started!
    update(status: 'awaiting_resolution')
    side_bet_acceptances.update_all(status: 'awaiting_resolution')
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

  def valid_winner
    return if [game.user_id, game.opponent_id].include?(predicted_winner_id)

    errors.add(:predicted_winner_id, "was somehow not one of the two involved players; either you're trying some whack shit, or this shit is fucked up, so let me know if it's the latter.")
  end
end
