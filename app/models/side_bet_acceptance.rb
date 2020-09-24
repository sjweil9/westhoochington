class SideBetAcceptance < ApplicationRecord
  belongs_to :user

  def side_bet
    @side_bet ||= case bet_type
                  when 'game' then GameSideBet.find(side_bet_id)
                  when 'season' then SeasonSideBet.find(side_bet_id)
                  end
  end

  before_validation :set_defaults

  BET_STATUSES = %w[awaiting_resolution awaiting_payment awaiting_confirmation completed]

  BET_STATUSES.each do |status|
    define_method("#{status}?") { self.status == status }
  end

  def loser_id
    side_bet.predictor_won? ? user_id : side_bet.user_id
  end

  def winner_id
    side_bet.predictor_won? ? side_bet.user_id : user_id
  end

  private

  def set_defaults
    self.status ||= 'awaiting_resolution'
  end
end
