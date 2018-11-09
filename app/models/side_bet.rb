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
    in: 5..80,
    message: 'must be 5-80 characters. Let me know if that really isnt gonna cut it for ya.',
  }

  before_create :set_defaults

  def process_update(status)
    taker_status = status == 'takers' ? 'won' : 'lost'
    self.completed = true
    self.status = status
    side_bet_acceptances.update(status: taker_status)
    save
  end

  def maxed_out?
    max_takers && side_bet_acceptances.count >= max_takers
  end

  private

  def set_defaults
    self.completed = false
    self.status = 'pending'
  end
end
