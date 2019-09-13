class UserNotificationsMailer < ApplicationMailer
  default :from => 'lynchpin@westhoochington.com'

  def send_signup_email(user)
    @user = user
    mail( :to => @user.email,
    :subject => 'Welcome to Westhoochington.com, you cuck bastard.' )
  end

  def send_newsletter(emails, week, year)
    @year = year
    @week = week
    @games = Game.includes(game_joins).references(game_joins).where(week: @week, season_year: @year).all
    @users = User.includes(user_joins).references(user_joins).where(id: @games.map(&:user_id)).all
    @overperformer = @users.sort_by { |a| -a.send("points_above_average_for_week_#{@year}", @week) }.first
    @outprojector = @users.sort_by { |a| -a.send("points_above_projection_for_week_#{@year}", @week) }.first
    @narrowest = @games.sort_by { |a| a.margin.abs }.first
    @largest = @games.sort_by { |a| -a.margin.abs }.first
    @high_score = @games.detect { |game| game.weekly_high_score?(@games) }
    set_random_messages!
    mail(to: emails, subject: "Weekly Westhoochington - #{year} ##{week}")
  end

  def send_podcast_blast(subject, body, podcast_link)
    users = User.where(podcast_flag: true).all
    @body = body
    @url = podcast_link
    mail(to: users.map(&:email), subject: subject)
  end

  private

  def game_joins
    %i[user opponent]
  end

  def user_joins
    [:"games_#{@year}", :"opponent_games_#{@year}", nicknames: :votes]
  end

  def set_random_messages!
    @high_score_message = random_high_score_message
    @narrowest_cucking_message = random_narrow_cucking_message
  end

  def random_high_score_message
    i18n_key = if @high_score.active_total > 150
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
end
