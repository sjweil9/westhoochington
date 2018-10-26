class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  before_create :default_name
  validate :allowed_email

  private

  ALLOWED_EMAILS = ['test@test.com']
  JOKERS = {
    'stephen.weil@gmail.com':'Stephen Weil',
    'test@test.com':'Test User'
  }

  def default_name
    self.name = JOKERS[self.email]
  end

  def allowed_email
    return if ALLOWED_EMAILS.include?(email)
    errors.add(:email, 'Double check your email, or... who the fuck are you?')
  end
end
