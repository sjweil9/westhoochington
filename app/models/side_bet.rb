class SideBet < ApplicationRecord
  belongs_to :user
  has_many :side_bet_acceptances

  before_create :set_defaults

  private

  def set_defaults
    self.completed = false
  end
end
