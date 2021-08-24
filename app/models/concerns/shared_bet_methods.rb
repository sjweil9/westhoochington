module SharedBetMethods
  BET_STATUSES = %w[awaiting_bets awaiting_resolution awaiting_payment awaiting_confirmation completed]

  BET_STATUSES.each do |status|
    define_method("#{status}?") { self.status == status }
  end

  def valid_to_cancel?(current_user_id)
    return false if side_bet_acceptances.count.positive?

    user_id&.to_i == current_user_id&.to_i
  end

  def proposer_payout
    return amount unless odds.present?

    amount * odds.split(':').last.to_i
  end

  def acceptor_payout
    return amount unless odds.present?

    amount * odds.split(':').first.to_i
  end

  def pending?
    !finished?
  end

  def finished?
    raise "must implement finished? in bet subclass"
  end

  def valid_status
    return if BET_STATUSES.include?(status)

    errors.add(:status, "must be one of #{BET_STATUSES.join(', ')}")
  end

  def set_defaults
    self.status ||= 'awaiting_bets'
    self.line ||= 0
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

  def valid_for_user_acceptance?(current_user_id)
    user_id != current_user_id &&
      (maximum_acceptors.blank? || side_bet_acceptances.size < maximum_acceptors) &&
      side_bet_acceptances.none? { |sba| sba.user_id == current_user_id } &&
      valid_acceptor_ids.include?(current_user_id)
  end

  def cant_accept_reason(current_user_id)
    if self.is_a?(GameSideBet) && game.started?
      "Game has already started."
    elsif user_id == current_user_id
      "This is your own bet."
    elsif maximum_acceptors.present? && side_bet_acceptances.size >= maximum_acceptors
      "Already reached the maximum of #{maximum_acceptors} acceptors."
    elsif side_bet_acceptances.any? { |sba| sba.user_id == current_user_id }
      "You have already accepted this bet"
    elsif possible_acceptances&.dig('users').present? && possible_acceptances&.dig('users').exclude?(current_user_id)
      "You are not in the list of players for whom this bet was proposed."
    end
  end

  def valid_acceptor_ids
    possible_acceptances&.dig('users').presence || User.pluck(:id)
  end

  def maximum_acceptors
    possible_acceptances&.dig('max')
  end

  def update_calculated_stats
    CalculateStatsJob.new.update_side_hustles(self)
  end

  def winner_nickname
    Rails.cache.fetch("nickname_#{bet_terms['winner_id']}") { User.find(bet_terms["winner_id"]).random_nickname }
  end

  def loser_nickname
    Rails.cache.fetch("nickname_#{bet_terms['loser_id']}") { User.find(bet_terms["loser_id"]).random_nickname }
  end

  def player_nickname
    Rails.cache.fetch("nickname_#{bet_terms['player_id']}") { User.find(bet_terms["player_id"]).random_nickname }
  end

  def amount_clarification
    return unless odds && odds != "1:1"

    "If you accept, you risk #{risk_amount} to win #{win_amount}."
  end

  def win_amount
    win_weight, _ = odds.split(":")
    to_currency(amount * win_weight.to_f)
  end

  def risk_amount
    _, risk_weight = odds.split(":")
    to_currency(amount * risk_weight.to_f)
  end
end