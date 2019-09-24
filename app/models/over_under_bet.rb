class OverUnderBet < ApplicationRecord
  belongs_to :user
  belongs_to :line

  def created_by_user?
    user.id == Thread.current[:current_user][:id]
  end

  def direction
    over ? 'Over' : 'Under'
  end
end
