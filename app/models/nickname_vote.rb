class NicknameVote < ApplicationRecord
  belongs_to :user
  belongs_to :nickname

  validates :user, uniqueness: { scope: :nickname }
  validates :value, numericality: { only_integer: true }

  def down?
    value.negative?
  end

  def up?
    value.positive?
  end
end
