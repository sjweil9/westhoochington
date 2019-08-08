class SideBet < ApplicationRecord
  belongs_to :user
  has_many :side_bet_acceptances

  validates :amount, numericality: { greater_than: 0 }
  validates :max_takers, numericality: {
    allow_nil: true,
    greater_than: 0,
    only_integer: true,
  }
  validates :terms, length: {
    in: 1..80,
    message: 'must be 1-80 characters. Let me know if that really isnt gonna cut it for ya.',
  }

  before_create :set_defaults

  def process_update(status)
    taker_status = status == 'takers' ? 'won' : 'lost'
    self.completed = true
    self.completed_date = Time.now
    self.status = status
    side_bet_acceptances.update(status: taker_status)
    save
  end

  def maxed_out?
    max_takers && side_bet_acceptances.count >= max_takers
  end

  def completed?
    completed || closed?
  end

  def closed?
    closing_date && closing_date <= Time.now
  end

  def won?
    status == 'proposer'
  end

  def lost?
    status == 'takers'
  end

  def winners
    return unless completed?

    status == 'takers' ? side_bet_acceptances.map(&:user) : [user]
  end

  def check_paid_status!
    update(paid: true) if side_bet_acceptances.all?(&:paid?)
  end

  private

  def set_defaults
    self.completed = false
    self.status = 'pending'
    self.paid = false
  end
end
