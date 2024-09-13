class UserNotificationsMailer < ApplicationMailer
  default :from => 'lynchpin@westhoochington.com'

  def send_signup_email(user)
    @user = user
    mail( :to => @user.email,
    :subject => 'Welcome to Westhoochington.com, you cuck bastard.' )
  end

  def send_keep_alive
    mail(to: "stephen.weil@gmail.com", subject: "WestHoochIngton Keep Alive")
  end

  def send_newsletter(emails, week, year)
    set_basic_variables(week, year)
    @overperformer = @users.sort_by { |a| -a.send("points_above_average_for_week_#{@year}", @week) }.first
    @outprojector = @users.sort_by { |a| -a.send("points_above_projection_for_week_#{@year}", @week) }.first
    @narrowest = @games.sort_by { |a| a.margin.abs }.first
    @largest = @games.sort_by { |a| -a.margin.abs }.first
    @high_score = @games.detect { |game| game.weekly_high_score?(@games) }
    set_random_messages!
    mail(to: emails, subject: "Weekly Westhoochington - #{year} ##{week}")
  end

  def send_playoff_newsletter(emails, week, year)
    set_basic_variables(week, year, true)
    @championship_games = @games.select { |game| championship_bracket?(game) }
    @irrelevant_games = @games.select { |game| irrelevant?(game) }
    @sacko_games = @games.select { |game| sacko?(game) }
    if @week >= 16
      @championship_game = @championship_games.detect { |game| game.user.send("games_#{@year}").detect { |g| g.week == 14 }.won? }
      @third_place_game = @championship_games.detect { |game| game.user.send("games_#{@year}").detect { |g| g.week == 14 }.lost? }
    end
    set_random_playoff_messages!
    mail(to: emails, subject: "Weekly Westhoochington - #{year} Playoffs - Week #{week - 13}")
  end

  def send_podcast_blast(subject, body, podcast_link)
    users = User.where(podcast_flag: true).all
    @body = body
    @url = podcast_link
    mail(to: users.map(&:email), subject: subject)
  end

  private

  def set_basic_variables(week, year, playoff = false)
    @year = year
    @week = week
    @games = Game.includes(game_joins).references(game_joins).where(week: [15, 17].include?(@week) ? @week - 1 : @week, season_year: @year).all
    @games = Game.unscoped.includes(game_joins).references(game_joins).where(week: [15, 17].include?(@week) ? @week - 1 : @week, season_year: @year).all if playoff
    @season_games = Game.includes(game_joins).references(game_joins).where(season_year: @year).all
    @users = User.includes(user_joins).references(user_joins).where(id: @games.map(&:user_id)).all
    @trend_breakers = calculate_trend_breakers
    @record_setters = calculate_record_setters
    @resolved_side_hustles = GameSideBet.where(game_id: @games.map(&:id)).all.map(&:side_bet_acceptances).flatten
  end

  def championship_bracket?(game)
    game.user.playoff_seed(@year) <= 4 && game.user.playoff_seed(@year) < game.opponent.playoff_seed(@year)
  end

  def irrelevant?(game)
    return false if championship_bracket?(game)
    return false unless game.user.playoff_seed(@year) < game.opponent.playoff_seed(@year)
    return true if [5, 6, 7, 8].include?(game.user.playoff_seed(@year))
    return false unless @week >= 16

    game.user.send("games_#{@year}").detect { |game| game.week == 14 }.won?
  end

  def sacko?(game)
    return false unless game.user.playoff_seed(@year) < game.opponent.playoff_seed(@year)

    game.user.playoff_seed(@year) >= 9 && !irrelevant?(game)
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
      record = game.user.calculated_stats.lifetime_record.dig(game.opponent_id.to_s, 'record_string')
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

  def calculate_record_setters
    {
      high_scores: calculate_new_high_scores,
      low_scores: calculate_new_low_scores,
      large_margins: calculate_new_large_margin,
      narrow_margins: calculate_new_narrow_margin,
    }
  end

  def calculate_new_high_scores
    @games.reduce([]) do |memo, game|
      index = gls.highest_score_espn.index do |sc|
        sc['week'].to_i == game.week.to_i &&
          sc['year'].to_i == game.season_year.to_i &&
          sc['player_id'].to_i == game.user_id.to_i
      end
      if index
        memo + [{ rank: index + 1, player_id: game.user_id, opponent_id: game.opponent_id, score: game.active_total }]
      else
        memo
      end
    end
  end

  def calculate_new_low_scores
    @games.reduce([]) do |memo, game|
      index = gls.lowest_score.index do |sc|
        sc['week'].to_i == game.week.to_i &&
          sc['year'].to_i == game.season_year.to_i &&
          sc['player_id'].to_i == game.user_id.to_i
      end
      if index
        memo + [{ rank: index + 1, player_id: game.user_id, opponent_id: game.opponent_id, score: game.active_total }]
      else
        memo
      end
    end
  end

  def calculate_new_large_margin
    @games.reduce([]) do |memo, game|
      game_data = gls.largest_margin.detect do |sc|
        sc['week'].to_i == game.week.to_i &&
          sc['year'].to_i == game.season_year.to_i &&
          sc['player_id'].to_i == game.user_id.to_i
      end
      if game_data
        index = gls.largest_margin.index(game_data) + 1
        memo + [game_data.with_indifferent_access.merge(rank: index)]
      else
        memo
      end
    end
  end

  def calculate_new_narrow_margin
    @games.reduce([]) do |memo, game|
      game_data = gls.narrowest_margin.detect do |sc|
        sc['week'].to_i == game.week.to_i &&
          sc['year'].to_i == game.season_year.to_i &&
          sc['player_id'].to_i == game.user_id.to_i
      end
      if game_data
        index = gls.narrowest_margin.index(game_data) + 1
        memo + [game_data.with_indifferent_access.merge(rank: index)]
      else
        memo
      end
    end
  end

  def gls
    @gls ||= GameLevelStat.first
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
    win_key = [15, 17].include?(@week.to_i) ? 'won' : 'winning'

    @narrow_win_messages = I18n.t("newsletter.playoffs.#{win_key}.narrow").keys.map { |key| ["newsletter.playoffs.#{win_key}.narrow", key].join('.') }
    @medium_win_messages = I18n.t("newsletter.playoffs.#{win_key}.medium").keys.map { |key| ["newsletter.playoffs.#{win_key}.medium", key].join('.') }
    @big_win_messages = I18n.t("newsletter.playoffs.#{win_key}.big").keys.map { |key| ["newsletter.playoffs.#{win_key}.big", key].join('.') }
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
    level = if @high_score.active_total > 180
                 'crushed'
               elsif @high_score.active_total > 150
                 'very_high'
               elsif @high_score.active_total > 130
                 'high'
               elsif @high_score.active_total < 125
                 'low'
               else
                 'medium'
               end
    possible_messages = NewsletterMessage.where(category: 'high_score', level: level, used: 0)
    message = if possible_messages.size.zero?
                NewsletterMessage.where(category: 'high_score', level: level).weighted_random.first
              else
                possible_messages.sample
              end
    replace_anchors(message, player: @high_score.winner.random_nickname, score: @high_score.active_total)
  end

  def replace_anchors(message, values)
    message.use_message.gsub(/%\{\w+\}/) { |val| values[val.gsub(/[%{}]/, '').to_sym] || val }
  end

  def random_narrow_cucking_message
    level = if @narrowest.margin.abs < 5
                 'very_narrow'
               elsif @narrowest.margin.abs < 10
                 'medium'
               else
                 'not_narrow'
            end
    possible_messages = NewsletterMessage.where(category: 'narrowest', level: level, used: 0)
    message = if possible_messages.size.zero?
                NewsletterMessage.where(category: 'narrowest', level: level).weighted_random.first
              else
                possible_messages.sample
              end
    replace_anchors(message, winner: @narrowest.winner.random_nickname, loser: @narrowest.loser.random_nickname, margin: @narrowest.margin.abs)
  end

  def random_biggest_bagging_message
    level = if @largest.margin.abs > 50
                 'very_large'
               elsif @largest.margin.abs > 30
                 'large'
               elsif @largest.margin.abs > 10
                 'medium'
               else
                 'small'
               end
    possible_messages = NewsletterMessage.where(category: 'biggest', level: level, used: 0)
    message = if possible_messages.size.zero?
                NewsletterMessage.where(category: 'biggest', level: level).weighted_random.first
              else
                possible_messages.sample
              end
    replace_anchors(message, winner: @largest.winner.random_nickname, loser: @largest.loser.random_nickname, margin: @largest.margin.abs)
  end

  def random_overperformer_message
    level = if @overperformer.send("points_above_average_for_week_#{@year}", @week) > 30
                 'large'
               elsif @overperformer.send("points_above_average_for_week_#{@year}", @week) > 10
                 'medium'
               else
                 'low'
               end
    possible_messages = NewsletterMessage.where(category: 'overperformer', level: level, used: 0)
    message = if possible_messages.size.zero?
                NewsletterMessage.where(category: 'overperformer', level: level).weighted_random.first
              else
                possible_messages.sample
              end
    replace_anchors(message, player: @overperformer.random_nickname, points: @overperformer.send("game_for_week_#{@year}", @week)&.active_total, average: @overperformer.send("average_active_total_#{@year}"))
  end

  def random_projections_message
    level = if @outprojector.send("points_above_projection_for_week_#{@year}", @week) > 30
                 'large'
               elsif @outprojector.send("points_above_projection_for_week_#{@year}", @week) > 10
                 'medium'
               else
                 'low'
               end
    possible_messages = NewsletterMessage.where(category: 'outprojector', level: level, used: 0)
    message = if possible_messages.size.zero?
                NewsletterMessage.where(category: 'outprojector', level: level).weighted_random.first
              else
                possible_messages.sample
              end
    replace_anchors(message, player: @outprojector.random_nickname, points: @outprojector.send("game_for_week_#{@year}", @week)&.active_total, projected: @outprojector.send("game_for_week_#{@year}", @week)&.projected_total&.round(2))
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
