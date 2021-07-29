class SideBetAcceptance < ApplicationRecord
  belongs_to :user

  def side_bet
    @side_bet ||= case bet_type
                  when 'game' then GameSideBet.find(side_bet_id)
                  when 'season' then SeasonSideBet.find(side_bet_id)
                  end
  end

  before_validation :set_defaults
  after_create :post_to_discord

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

  def confirm_payment!
    update(status: 'completed')
    return unless side_bet.side_bet_acceptances.all?(&:completed?)

    side_bet.update(status: 'completed')
  end

  def mark_payment_sent!
    update(status: 'awaiting_confirmation')
    return unless side_bet.side_bet_acceptances.all? { |sba| sba.awaiting_confirmation? || sba.completed? }

    side_bet.update(status: 'awaiting_confirmation')
  end

  private

  def set_defaults
    self.status ||= 'awaiting_resolution'
  end

  def post_to_discord
    Discord::Messages::SideBetAcceptanceJob.perform_now(self)
  end
end
