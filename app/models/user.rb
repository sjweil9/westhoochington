class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  validate :allowed_email

  has_many :nicknames, dependent: :destroy

  after_create :default_nickname

  def random_nickname
    nicknames.sample&.name
  end

  private

  ALLOWED_EMAILS = ['test@test.com', 'user@user.com', 'cuck@boi.com']
  NICKNAME = {
    'user@user.com': 'User boi fresh',
    'cuck@boi.com': 'Amazing Blowhole',
  }.with_indifferent_access

  def allowed_email
    return if ALLOWED_EMAILS.include?(email)

    errors.add(:email, 'Double check your email, or... who the fuck are you?')
  end

  def default_nickname
    Nickname.create(user_id: id, name: NICKNAME[email])
  end
end
