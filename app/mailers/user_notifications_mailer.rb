class UserNotificationsMailer < ApplicationMailer
  default :from => 'lynchpin@westhoochington.com'

  def send_signup_email(user)
    @user = user
    mail( :to => @user.email,
    :subject => 'Welcome to Westhoochington.com, you cuck bastard.' )
  end

  def send_newsletter(user, week, year)
    @user = user
    @year = year
    @week = week
    @games = Game.includes(game_joins).references(game_joins).where(week: @week, season_year: @year).all
    @users = User.includes(user_joins).references(user_joins).where(id: @games.map(&:user_id)).all
    @overperformer = @users.sort_by { |a| -a.send("points_above_average_for_week_#{@year}", @week) }.first
    @outprojector = @users.sort_by { |a| -a.send("points_above_projection_for_week_#{@year}", @week) }.first
    @narrowest = @games.sort_by { |a| a.margin.abs }.first
    @largest = @games.sort_by { |a| -a.margin.abs }.first
    @high_score = @games.detect { |game| game.weekly_high_score?(@games) }
    mail(to: @user.email, subject: "Weekly Westhoochington - #{year} ##{week}")
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
end
