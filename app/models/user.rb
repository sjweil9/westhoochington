class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  validate :allowed_email

  has_many :nicknames, dependent: :destroy
  has_many :games
  has_many :opponent_games, class_name: 'Game', foreign_key: :opponent_id
  has_many :side_bets
  has_many :side_bet_acceptances

  after_create :default_nicknames

  def random_nickname
    @random_nickname ||= weighted_nicknames.sample&.name
  end

  def weighted_nicknames
    nicknames.map do |nickname|
      downvotes = nickname.votes.select(&:down?).size
      upvotes = nickname.votes.select(&:up?).size
      weight = 10 - downvotes + upvotes
      arr = []
      weight.times { arr << nickname }
      arr
    end.flatten
  end

  #
  # stat related methods
  #

  %w[active_total bench_total projected_total opponent_active_total].each do |method|
    define_method(:"yearly_#{method}") do
      games.map(&:"#{method}").reduce(:+).to_f.round(2)
    end

    define_method(:"average_#{method}") do
      (send(:"yearly_#{method}") / game_count).round(2)
    end
    
    define_method(:"yearly_opponent_#{method}") do
      opponent_games.map(&:"#{method}").reduce(:+).to_f.round(2)
    end

    define_method(:"average_opponent_#{method}") do
      (send(:"yearly_opponent_#{method}") / opponent_game_count).round(2)
    end
  end

  def lucky_wins
    # games where you won, but would have lost to opponent's average score
    games.select(&:lucky?).count
  end

  def unlucky_losses
    # games where you lost, but would have beaten opponent's average score
    games.select(&:unlucky?).count
  end

  %w[margin_of_victory margin_of_defeat].each do |method|
    define_method(:"total_#{method}") do
      check = method == 'margin_of_victory' ? 'won?' : 'lost?'
      games.select(&:"#{check}").map(&:margin).reduce(:+).to_f.round(2)
    end

    define_method(:"average_#{method}") do
      (send(:"total_#{method}") / game_count).round(2)
    end
  end

  def average_scoring_margin
    (games.map(&:margin).reduce(:+).to_f / game_count).round(2)
  end

  def average_points_above_projection
    (games.map(&:points_above_projection).reduce(:+).to_f / game_count).round(2)
  end

  def wins
    # must be .size, .count gets treated as query
    games.select(&:won?).size
  end

  def losses
    games.select(&:lost?).size
  end

  def projected_wins
    # must be .size, .count gets treated as query
    games.select(&:projected_win?).size
  end

  def wins_above_projections
    wins - projected_wins
  end

  WEEKLY_METHODS = %w[
    margin
    points_above_projection
    bench_total
    points_above_opponent_average
    points_above_average
  ].freeze

  WEEKLY_METHODS.each do |method|
    define_method(:"#{method}_for_week") do |week|
      game_for(week)&.send(method).to_f.round(2)
    end
  end

  def game_for(week)
    games.find(&:"week#{week}?")
  end

  def total_high_weekly_scores(passed_games = nil)
    @total_high_weekly_scores ||= (passed_games.select { |pg| pg.user_id == id } || games).select { |g| g.weekly_high_score?(passed_games) }.count
  end

  def game_count
    @game_count ||= games.size.to_f
  end

  def opponent_game_count
    @opponent_game_count ||= opponent_games.size.to_f
  end

  def matchup_independent_record(games = nil)
    @matchup_independent_records ||= {}
    season_year = games&.first&.week || Date.today.year.to_s
    return @matchup_independent_records[season_year] if @matchup_independent_records[season_year].present?

    games ||= Game.where(season_year: season_year)

    games_for_year = []
    other_user_games = []

    games.each do |game|
      games_for_year << game if game.user_id == id
      other_user_games << game if game.user_id != id
    end

    win, loss, tie = games_for_year.reduce([0, 0, 0]) do |memo, game|
      week = game.week
      other_user_games.each do |other_game|
        next unless other_game.week == week

        if game.active_total > other_game.active_total
          memo[0] += 1
        elsif game.active_total < other_game.active_total
          memo[1] += 1
        else
          memo[2] += 1
        end
      end
      memo
    end
    @matchup_independent_records[season_year] = "#{win} - #{loss} - #{tie}"
  end

  #
  ## side bet methods
  #

  def side_bet_wins
    return @side_bet_wins if @side_bet_wins.present?

    proposed_wins = side_bets.where(status: 'proposer', completed: true).count
    accepted_wins = side_bet_acceptances.where(status: 'won').count
    @side_bet_wins = proposed_wins + accepted_wins
  end

  def side_bet_losses
    return @side_bet_losses if @side_bet_losses.present?

    proposed_losses = side_bets.where(status: 'takers', completed: true).count
    accepted_losses = side_bet_acceptances.where(status: 'lost').count
    @side_bet_losses = proposed_losses + accepted_losses
  end

  def pending_side_bets
    return @pending_side_bets if @pending_side_bets.present?

    proposed_pending = side_bets.where(status: 'pending', completed: false).count
    accepted_pending = side_bet_acceptances.where(status: 'pending').count
    @pending_side_bets = proposed_pending + accepted_pending
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
    'ovaisinamullah@gmail.com': ['The Commish', 'Ovals'],
    'tonypelli@gmail.com': ['T-Pain'],
    'mikelacy3@gmail.com': ['McLacy', 'The Effect', 'Ron Mexico'],
    'goblue101@gmail.com': ['Patch', 'P-Stick', "O'Hoolihan"],
    'pkaushish@gmail.com': ['Nav', 'Saquon Sucker'],
    'adamkos101@gmail.com': ['Cleaver', 'Young Koz'],
    'stephen.weil@gmail.com': ['Lynchpin Stevie'],
    'captrf@gmail.com': ['Senghas', 'Matthew'],
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
