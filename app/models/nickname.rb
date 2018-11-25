class Nickname < ApplicationRecord
  belongs_to :user
  has_many :votes, class_name: 'NicknameVote'

  TROLL_MESSAGE = <<~TROLL
    must be 1 to 50 characters. I know... 
    it would have been pretty funny, but be reasonable, 
    you fucking troll.
  TROLL

  CLEVER_MESSAGE = <<~CLEVER
    must be created by someone else... Seriously, what kind of 
    clever fuck are you? Thinking you could pad your own nicknames... 
    Low, dude.
  CLEVER

  validates_uniqueness_of :name, scope: :user_id
  validates :name, length: { in: 1..50, message: TROLL_MESSAGE }
  validate :other_user

  private

  def other_user
    return if Thread.current[:current_user].nil? || user_id != Thread.current[:current_user][:id]

    errors.add(:name, CLEVER_MESSAGE)
  end
end
