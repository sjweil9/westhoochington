class UserNotificationsMailer < ApplicationMailer
  default :from => 'lynchpin@westhoochington.com'

  def send_signup_email(user)
    @user = user
    mail( :to => @user.email,
    :subject => 'Welcome to Westhoochington.com, you cuck bastard.' )
  end

  def send_newsletter(emails, week, year)
    set_basic_variables(week, year)
    @overperformer = @users.sort_by { |a| -a.send("points_above_average_for_week_#{@year}", @week) }.first
    @outprojector = @users.sort_by { |a| -a.send("points_above_projection_for_week_#{@year}", @week) }.first
    @narrowest = @games.sort_by { |a| a.margin.abs }.first
    @largest = @games.sort_by { |a| -a.margin.abs }.first
    @high_score = @games.detect { |game| game.weekly_high_score?(@games) }
    @new_over_unders = OverUnder.includes(user: :nicknames).references(user: :nicknames).where(created_at: last_week).all
    @new_over_under_lines = Line.includes(:over_under, user: :nicknames).references(:over_under, user: :nicknames).where(created_at: last_week).all
    @new_over_under_bets = OverUnderBet.includes(user: :nicknames, line: :over_under).references(user: :nicknames, line: :over_under).where(created_at: last_week).all
    @trend_breakers = calculate_trend_breakers
    set_random_messages!
    mail(to: emails, subject: "Weekly Westhoochington - #{year} ##{week}")
  end

  def send_playoff_newsletter(emails, week, year)
    set_basic_variables(week, year)
    @championship_games = @games.select { |game| championship_bracket?(game) }
    @irrelevant_games = @games.select { |game| irrelevant?(game) }
    @sacko_games = @games.select { |game| sacko?(game) }
    set_random_playoff_messages!
    mail(to: emails, subject: "Weekly Westhoochington - #{year} Playoffs - Week #{week - 12}")
  end

  def send_podcast_blast(subject, body, podcast_link)
    users = User.where(podcast_flag: true).all
    @body = body
    @url = podcast_link
    mail(to: users.map(&:email), subject: subject)
  end

  private

  def set_basic_variables(week, year)
    @year = year
    @week = week
    @games = Game.includes(game_joins).references(game_joins).where(week: @week, season_year: @year).all
    @season_games = Game.includes(game_joins).references(game_joins).where(season_year: @year).all
    @users = User.includes(user_joins).references(user_joins).where(id: @games.map(&:user_id)).all
  end

  def championship_bracket?(game)
    game.user.playoff_seed(@year) <= 4 && game.user.playoff_seed(@year) < game.opponent.playoff_seed(@year)
  end

  def irrelevant?(game)
    return false unless game.user.playoff_seed(@year) < game.opponent.playoff_seed(@year)
    return true if [5, 6].include?(game.user.playoff_seed(@year))
    return false unless @week >= 15

    game.user.send("games_#{@year}").detect { |game| game.week == 13 }.won?
  end

  def sacko?(game)
    return false unless game.user.playoff_seed(@year) < game.opponent.playoff_seed(@year)

    game.user.playoff_seed(@year) >= 7 && !irrelevant?(game)
  end

  def last_week
    (Time.now - 7.days)..Time.now
  end

  def game_joins
    %i[user opponent]
  end

  def user_joins
    [:"games_#{@year}", :"opponent_games_#{@year}", nicknames: :votes]
  end

  def calculate_trend_breakers
    @games.reduce(tie: [], lead: [], trend: []) do |memo, game|
      record = game.user.lifetime_record_against(game.opponent)
      if established_tie?(record, game)
        memo[:tie] << game
      elsif took_lead?(record, game)
        memo[:lead] << game
      elsif broke_trend?(record, game)
        memo[:trend] << game
      end
      memo
    end
  end

  def established_tie?(record, game)
    # only count ties from behind so you get only one of the two applicable games
    win, loss, _draw = record.split(' - ').map(&:to_i)
    game.won? && (loss == win)
  end

  def took_lead?(record, game)
    win, loss, _draw = record.split(' - ').map(&:to_i)
    game.won? && ((win - loss) == 1)
  end

  def broke_trend?(record, game)
    win, loss, _draw = record.split(' - ').map(&:to_i)
    game.won? && ((loss - win) > 2)
  end

  def set_random_messages!
    @high_score_message = random_high_score_message
    @narrowest_cucking_message = random_narrow_cucking_message
    @biggest_bagging_message = random_biggest_bagging_message
    @overperformer_message = random_overperformer_message
    @projections_message = random_projections_message
    @standings_message = random_standings_message
    @mis_header, @mis_body_lines = random_mis_message
  end

  def set_random_playoff_messages!
    return set_random_playoff_round_over_messages! if [14, 16].include?(@week.to_i)

    @narrow_win_messages = I18n.t('newsletter.playoffs.winning.narrow').keys.map { |key| ['newsletter.playoffs.winning.narrow', key].join('.') }
    @medium_win_messages = I18n.t('newsletter.playoffs.winning.medium').keys.map { |key| ['newsletter.playoffs.winning.medium', key].join('.') }
    @big_win_messages = I18n.t('newsletter.playoffs.winning.big').keys.map { |key| ['newsletter.playoffs.winning.big', key].join('.') }
    @words_of_wisdom = random_playoff_wisdom
  end

  def set_random_playoff_round_over_messages!
    # TODO: messages for second week of each playoff round
  end

  def random_playoff_wisdom
    base_key = 'newsletter.playoffs.wisdom'
    possible_messages = I18n.t(base_key).keys
    I18n.t([base_key, possible_messages.sample].join('.'))
  end

  def random_high_score_message
    i18n_key = if @high_score.active_total > 180
                 'newsletter.high_score.crushed'
               elsif @high_score.active_total > 150
                 'newsletter.high_score.very_high'
               elsif @high_score.active_total > 130
                 'newsletter.high_score.high'
               elsif @high_score.active_total < 120
                 'newsletter.high_score.low'
               else
                 'newsletter.high_score.medium'
               end
    possible_messages = I18n.t(i18n_key).keys
    I18n.t([i18n_key, possible_messages.sample].join('.'), nickname: @high_score.winner.random_nickname, score: @high_score.active_total)
  end

  def random_narrow_cucking_message
    i18n_key = if @narrowest.margin.abs < 5
                 'newsletter.narrowest.very_narrow'
               elsif @narrowest.margin.abs < 10
                 'newsletter.narrowest.medium'
               else
                 'newsletter.narrowest.not_narrow'
               end
    possible_messages = I18n.t(i18n_key).keys
    I18n.t([i18n_key, possible_messages.sample].join('.'), winner: @narrowest.winner.random_nickname, loser: @narrowest.loser.random_nickname, margin: @narrowest.margin.abs)
  end

  def random_biggest_bagging_message
    i18n_key = if @largest.margin.abs > 50
                 'newsletter.biggest.very_large'
               elsif @largest.margin.abs > 30
                 'newsletter.biggest.large'
               elsif @largest.margin.abs > 10
                 'newsletter.biggest.medium'
               else
                 'newsletter.biggest.small'
               end
    possible_messages = I18n.t(i18n_key).keys
    I18n.t([i18n_key, possible_messages.sample].join('.'), winner: @largest.winner.random_nickname, loser: @largest.loser.random_nickname, margin: @largest.margin.abs)
  end

  def random_overperformer_message
    i18n_key = if @overperformer.send("points_above_average_for_week_#{@year}", @week) > 30
                 'newsletter.overperformer.big'
               elsif @overperformer.send("points_above_average_for_week_#{@year}", @week) > 10
                 'newsletter.overperformer.medium'
               else
                 'newsletter.overperformer.low'
               end
    possible_messages = I18n.t(i18n_key).keys
    I18n.t([i18n_key, possible_messages.sample].join('.'), name: @overperformer.random_nickname, points: @overperformer.send("game_for_week_#{@year}", @week)&.active_total, average: @overperformer.send("average_active_total_#{@year}"))
  end

  def random_projections_message
    i18n_key = if @outprojector.send("points_above_projection_for_week_#{@year}", @week) > 30
                 'newsletter.outprojector.high'
               elsif @outprojector.send("points_above_projection_for_week_#{@year}", @week) > 10
                 'newsletter.outprojector.medium'
               else
                 'newsletter.outprojector.low'
               end
    possible_messages = I18n.t(i18n_key).keys
    I18n.t([i18n_key, possible_messages.sample].join('.'), name: @outprojector.random_nickname, points: @outprojector.send("game_for_week_#{@year}", @week)&.active_total, projected: @outprojector.send("game_for_week_#{@year}", @week)&.projected_total&.round(2))
  end

  def random_standings_message
    base_key = 'newsletter.standings'
    possible_messages = I18n.t(base_key).keys
    I18n.t([base_key, possible_messages.sample].join('.'))
  end

  def random_mis_message
    base_key = 'newsletter.matchup_independent'
    possible_messages = I18n.t(base_key).keys
    selected_key = [base_key, possible_messages.sample].join('.')
    body_keys = I18n.t("#{selected_key}.body").keys
    body_lines = body_keys.map { |key| I18n.t("#{selected_key}.body.#{key}") }
    [I18n.t("#{selected_key}.header"), body_lines]
  end
end