class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  validate :allowed_email

  has_many :nicknames, dependent: :destroy
  has_many :games
  has_many :opponent_games, class_name: 'Game', foreign_key: :opponent_id

  after_create :default_nicknames

  def random_nickname
    nicknames.sample&.name
  end

  #
  # stat related methods
  #

  %w[active_total bench_total projected_total].each do |method|
    define_method(:"yearly_#{method}") do
      games.map(&:"#{method}").reduce(:+).round(2)
    end

    define_method(:"average_#{method}") do
      (send(:"yearly_#{method}") / game_count).round(2)
    end
    
    define_method(:"yearly_opponent_#{method}") do
      opponent_games.map(&:"#{method}").reduce(:+).round(2)
    end

    define_method(:"average_opponent_#{method}") do
      (send(:"yearly_opponent_#{method}") / opponent_game_count).round(2)
    end
  end

  def lucky_wins
    # games where you won, but would have lost to opponent's average score
    games.select(&:lucky?).count
  end

  %w[margin_of_victory margin_of_defeat].each do |method|
    define_method(:"total_#{method}") do
      check = method == 'margin_of_victory' ? 'won?' : 'lost?'
      games.select(&:"#{check}").map(&:point_differential).reduce(:+).round(2)
    end

    define_method(:"average_#{method}") do
      (send(:"total_#{method}") / game_count).round(2)
    end
  end

  def game_count
    @game_count ||= games.count.to_f
  end

  def opponent_game_count
    @opponent_game_count ||= opponent_games.count.to_f
  end

  private

  ALLOWED_EMAILS = [
    'test@test.com',
    'user@user.com',
    'cuck@boi.com',
    'ovaisinamullah@gmail.com',
    'tonypelli@gmail.com',
    'mikelacy3@gmail.com',
    'goblue101@gmail.com',
    'pkaushish@gmail.com',
    'adamkos101@gmail.com',
    'stephen.weil@gmail.com',
    'captrf@gmail.com',
    'seidmangar@gmail.com',
    'mattforetich4@gmail.com'
  ]

  NICKNAMES = {
    'user@user.com': ['User boi fresh'],
    'cuck@boi.com': ['Amazing Blowhole'],
    'ovaisinamullah@gmail.com': ['The Commish'],
    'tonypelli@gmail.com': ['T-Pain'],
    'mikelacy3@gmail.com': ['McLacy'],
    'goblue101@gmail.com': ['Patch'],
    'pkaushish@gmail.com': ['Nav'],
    'adamkos101@gmail.com': ['Cleaver'],
    'stephen.weil@gmail.com': ['Lynchpin Stevie'],
    'captrf@gmail.com': ['Senghas'],
    'seidmangar@gmail.com': ['Norwood'],
    'mattforetich4@gmail.com': ['Quadcock']
  }.with_indifferent_access

  def allowed_email
    return if ALLOWED_EMAILS.include?(email)

    errors.add(:email, 'Double check your email, or... who the fuck are you?')
  end

  def default_nicknames
    NICKNAMES[email].each do |nickname|
      Nickname.create(user_id: id, name: nickname)
    end
  end
end
