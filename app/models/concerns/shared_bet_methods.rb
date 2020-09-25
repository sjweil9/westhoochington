module SharedBetMethods
  BET_STATUSES = %w[awaiting_bets awaiting_resolution awaiting_payment awaiting_confirmation completed]

  BET_STATUSES.each do |status|
    define_method("#{status}?") { self.status == status }
  end

  def valid_status
    return if BET_STATUSES.include?(status)

    errors.add(:status, "must be one of #{BET_STATUSES.join(', ')}")
  end

  def set_defaults
    self.status ||= 'awaiting_bets'
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