class SideBetAcceptance < ApplicationRecord
  belongs_to :user

  def side_bet
    @side_bet ||= case bet_type
                  when 'game' then GameSideBet.find(side_bet_id)
                  when 'season' then SeasonSideBet.find(side_bet_id)
                  end
  end

  before_validation :set_defaults

  private

  def set_defaults
    self.status ||= 'awaiting_resolution'
  end
end
