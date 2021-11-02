class GameSideBet < ApplicationRecord
  include SharedBetMethods

  belongs_to :user
  has_many :side_bet_acceptances, -> { where(bet_type: 'game') }, foreign_key: :side_bet_id

  def game
    @game ||= Game.unscoped.find(game_id)
  end

  before_validation :set_defaults
  after_create :update_calculated_stats
  after_create :post_to_discord

  validate :valid_winner, :valid_status, :valid_odds, :valid_acceptances
  validates :amount, numericality: true
  validates :line, numericality: true

  def acceptor_condition_string
    "#{Rails.cache.fetch("nickname_#{accepting_winner_id}")} #{acceptor_line_description}"
  end

  def proposer_condition_string
    "#{Rails.cache.fetch("nickname_#{predicted_winner_id}")} #{proposer_line_description}"
  end

  def terms_description
    str = Rails.cache.fetch("nickname_#{predicted_winner_id}") { User.find(predicted_winner_id).random_nickname }
    str += " (#{line.positive? ? '+' + line.to_s : line})" if line.present? && !line.zero?
    str += " over #{Rails.cache.fetch("nickname_#{accepting_winner_id}") { User.find(accepting_winner_id).random_nickname }}"
    str
  end

  def game_finished!
    predictor_score_base = game.user_id == predicted_winner_id ? game.active_total : game.opponent_active_total
    acceptor_score_base = game.user_id == predicted_winner_id ? game.opponent_active_total : game.active_total
    functional_line = line || 0
    winner_id = predictor_score_base + functional_line > acceptor_score_base ? predicted_winner_id : accepting_winner_id
    update(status: 'awaiting_payment', actual_winner_id: winner_id)
    side_bet_acceptances.update_all(status: 'awaiting_payment')
    Discord::Messages::BetResolutionJob.perform_now(self)
    CalculateStatsJob.new.update_side_hustles(self)
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

  def finished?
    actual_winner_id.present?
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

  def post_to_discord
    Discord::Messages::GameSideBetJob.perform_now(self)
  end
end
