class SideBetAcceptance < ApplicationRecord
  belongs_to :side_bet
  belongs_to :user

  before_create :set_defaults

  %w[won pending lost].each do |method|
    define_method(:"#{method}?") { status == method }
  end

  def paid?
    paid
  end

  def mark_as_paid!
    update(paid: true)
    side_bet.check_paid_status!
  end

  private

  def set_defaults
    self.status = 'pending'
    self.paid = false
  end
end
