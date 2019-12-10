class GamesController < ApplicationController
  def index
    @year = params[:year] || Date.today.year
    @week = params[:week] || 'season'
    return weekly if @week && @week != 'season'

    @week = nil
    @games = Game.includes(game_joins).references(game_joins).where(season_year: params[:year])
    @users = User.includes(user_joins).references(user_joins).where(id: @games.map(&:user_id))
    @playoffs = @games.any?(&:playoff?)
    @completed = Season.find_by(season_year: @year)&.completed?
    render :index
  end

  def weekly
    @season = Season.find_by(season_year: @year) || Season.new(season_year: @year)
    @week = @week.to_i
    @week = @year.to_i >= 2019 && (@season&.two_game_playoff? || @season.nil?) && [14, 16].include?(@week) ? @week - 1 : @week
    if (games = Game.where(season_year: @year, week: @week)).present?
      @users = User.includes(user_joins).references(user_joins).where(id: games.map(&:user_id)).all
      @narrowest = Game.includes(game_joins).references(game_joins).where(week: @week, season_year: @year).all.sort_by { |a| a.margin.abs }.first
      @highest_score_game = Game.includes(user: :nicknames).references(user: :nicknames).where(week: @week, season_year: @year).all.find(&:weekly_high_score?)
      render :index
    else
      render :oops
    end
  end

  private

  def current_week
    # find highest week num in DB
    # old approach causes some issues during week-week transition
    # Time.now.strftime('%U').to_i - 35
    @current_week ||= Game.where(season_year: @year || Date.today.year).order(:week).reverse.first&.week || 0
  end

  def user_joins
    [:"games_#{@year}", :"opponent_games_#{@year}", :seasons, nicknames: :votes]
  end

  def game_joins
    [user: { nicknames: :votes }, opponent: { nicknames: :votes }]
  end
end
