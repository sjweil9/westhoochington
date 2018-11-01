class Line < ApplicationRecord
  belongs_to :over_under
  belongs_to :user

  has_many :over_under_bets
  has_many :over_bets, -> { where(over: true) }, class_name: 'OverUnderBet'
  has_many :under_bets, -> { where(over: false) }, class_name: 'OverUnderBet'

  validates_uniqueness_of :over_under_id, scope: :user_id
  validates :value, numericality: true

  def bet_on_by_user?
    over_bets.any?(&:created_by_user?) || under_bets.any?(&:created_by_user?)
  end

  def created_by_user?
    user.id == Thread.current[:current_user][:id]
  end
end
