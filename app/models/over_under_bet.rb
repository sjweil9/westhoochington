class OverUnderBet < ApplicationRecord
  belongs_to :user
  belongs_to :line

  def created_by_user?
    user.id == Thread.current[:current_user][:id]
  end
end
