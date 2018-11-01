class SideBetAcceptance < ApplicationRecord
  belongs_to :side_bet
  belongs_to :user

  before_create :set_defaults

  %w[won pending lost].each do |method|
    define_method(:"#{method}?") { status == method }
  end

  private

  def set_defaults
    self.status = 'pending'
  end
end
