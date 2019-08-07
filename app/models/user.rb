class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  validate :allowed_email

  has_many :nicknames, dependent: :destroy
  has_many :games, -> { where(season_year: Date.today.year ) }
  has_many :opponent_games, -> { where(season_year: Date.today.year) }, class_name: 'Game', foreign_key: :opponent_id
  has_many :historical_games, class_name: 'Game'
  has_many :side_bets
  has_many :side_bet_acceptances
  has_many :seasons

  (2015..Date.today.year).each do |year|
    has_many :"games_#{year}", -> { where(season_year: year) }, class_name: 'Game'
    has_many :"opponent_games_#{year}", -> { where(season_year: year)}, class_name: 'Game', foreign_key: :opponent_id
  end

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
  # season-level stat methods
  #

  def regular_rank(year)
    seasons.detect { |season| season.season_year.to_i == year.to_i }&.regular_rank&.to_i&.ordinalize
  end

  def playoff_rank(year)
    seasons.detect { |season| season.season_year.to_i == year.to_i }&.playoff_rank&.to_i&.ordinalize
  end

  def average_regular_season_finish
    season_count = seasons.size
    (seasons.map(&:regular_rank).reduce(:+) / season_count.to_f).round(2)
  end

  def average_final_finish
    season_count = seasons.size
    (seasons.map(&:playoff_rank).reduce(:+) / season_count.to_f).round(2)
  end

  #
  # stat related methods
  #

  (2015..Date.today.year).each do |year|
    %w[active_total bench_total projected_total opponent_active_total].each do |method|
      define_method(:"yearly_#{method}_#{year}") do
        send(:"games_#{year}").map(&:"#{method}").reduce(:+).to_f.round(2)
      end

      define_method(:"regular_yearly_#{method}_#{year}") do
        send(:"games_#{year}").reject(&:playoff?).map(&:"#{method}").reduce(:+).to_f.round(2)
      end

      define_method(:"playoff_yearly_#{method}_#{year}") do
        send(:"games_#{year}").select(&:playoff?).map(&:"#{method}").reduce(:+).to_f.round(2)
      end

      define_method(:"average_#{method}_#{year}") do
        return 0 unless send("game_count_#{year}").positive?

        (send(:"yearly_#{method}_#{year}") / send("game_count_#{year}")).round(2)
      end

      define_method(:"yearly_opponent_#{method}_#{year}") do
        send("opponent_games_#{year}").map(&:"#{method}").reduce(:+).to_f.round(2)
      end

      define_method(:"average_opponent_#{method}_#{year}") do
        return 0 unless send("opponent_game_count_#{year}").positive?

        (send(:"yearly_opponent_#{method}_#{year}") / send("opponent_game_count_#{year}")).round(2)
      end
    end

    define_method("lucky_wins_#{year}") do
      send(:"games_#{year}").select(&:lucky?).count
    end

    define_method("unlucky_losses_#{year}") do
      send(:"games_#{year}").select(&:unlucky?).count
    end

    %w[margin_of_victory margin_of_defeat].each do |method|
      define_method(:"total_#{method}_#{year}") do
        check = method == 'margin_of_victory' ? 'won?' : 'lost?'
        send(:"games_#{year}").select(&:"#{check}").map(&:margin).reduce(:+).to_f.round(2)
      end

      define_method(:"average_#{method}_#{year}") do
        return 0 unless send(:"game_count_#{year}").positive?

        (send(:"total_#{method}_#{year}") / send(:"game_count_#{year}")).round(2)
      end
    end

    define_method("average_scoring_margin_#{year}") do
      return 0 unless send(:"game_count_#{year}").positive?

      (send("games_#{year}").map(&:margin).reduce(:+).to_f / send(:"game_count_#{year}")).round(2)
    end

    define_method("average_points_above_projection_#{year}") do
      return 0 unless send(:"game_count_#{year}").positive?

      (send(:"games_#{year}").map(&:points_above_projection).reduce(:+).to_f / send(:"game_count_#{year}")).round(2)
    end

    define_method("regular_wins_#{year}") do
      send(:"games_#{year}").reject(&:playoff?).select(&:won?).size
    end

    define_method("regular_losses_#{year}") do
      send(:"games_#{year}").reject(&:playoff?).select(&:lost?).size
    end

    define_method("playoff_wins_#{year}") do
      send(:"games_#{year}").select(&:playoff?).select(&:won?).size
    end

    define_method("playoff_losses_#{year}") do
      send(:"games_#{year}").select(&:playoff?).select(&:lost?).size
    end

    define_method("wins_#{year}") do
      send(:"games_#{year}").select(&:won?).size
    end

    define_method("losses_#{year}") do
      send(:"games_#{year}").select(&:lost?).size
    end

    define_method("projected_wins_#{year}") do
      send(:"games_#{year}").select(&:projected_win?).size
    end

    define_method("wins_above_projections_#{year}") do
      send(:"wins_#{year}") - send(:"projected_wins_#{year}")
    end

    WEEKLY_METHODS = %w[
      margin
      points_above_projection
      bench_total
      points_above_opponent_average
      points_above_average
    ].freeze

    WEEKLY_METHODS.each do |method|
      define_method(:"#{method}_for_week_#{year}") do |week|
        send(:"game_for_week_#{year}", week)&.send(method).to_f.round(2)
      end
    end

    define_method("game_for_week_#{year}") do |week|
      send(:"games_#{year}").find(&:"week#{week}?")
    end

    define_method("total_high_weekly_scores_#{year}") do |passed_games = nil|
      var_name = :"@total_high_weekly_scores_#{year}"
      return instance_variable_get(var_name) if instance_variable_get(var_name)

      instance_variable_set(var_name, (passed_games.select { |pg| pg.user_id == id } || send(:"games_#{year}")).select { |g| g.weekly_high_score?(passed_games) }.count)
      instance_variable_get(var_name)
    end

    define_method("game_count_#{year}") do
      var_name = :"@game_count_#{year}"
      return instance_variable_get(var_name) if instance_variable_get(var_name)

      instance_variable_set(var_name, send(:"games_#{year}").size.to_f)
      instance_variable_get(var_name)
    end

    define_method("opponent_game_count_#{year}") do
      var_name = :"@opponent_game_count_#{year}"
      return instance_variable_get(var_name) if instance_variable_get(var_name)

      instance_variable_set(var_name, send(:"games_#{year}").size.to_f)
      instance_variable_get(var_name)
    end
  end

  def historical_wins
    historical_games.select(&:won?).size
  end

  def historical_losses
    historical_games.select(&:lost?).size
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
    'mattforetich4@gmail.com',
    'stewart.hackler@gmail.com',
    'sccrrckstr@gmail.com',
    'jstatham3@gmail.com',
    'john.rosensweig@gmail.com',
    'brandon.tricou@gmail.com'
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
    'mattforetich4@gmail.com': ['Quadcock'],
    'stewart.hackler@gmail.com':['Beef Stew'],
    'sccrrckstr@gmail.com':['Netanyahu'],
    'jstatham3@gmail.com':['Ty'],
    'john.rosensweig@gmail.com':['Rosenswag'],
    'brandon.tricou@gmail.com':['Brandon']
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
