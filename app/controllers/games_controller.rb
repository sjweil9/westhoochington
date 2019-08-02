class GamesController < ApplicationController
  def index
    @year = Date.today.year
    @games = Game.where(season_year: Date.today.year)
    user_ids = @games.map(&:user_id)
    @users = User.includes(user_joins).references(user_joins).where(id: user_ids).all
    binding.pry
  end

  def yearly
    @year = params[:year]
    joins = [:"games_#{@year}", :"opponent_games_#{@year}", nicknames: :votes]
    @games = Game.where(season_year: params[:year])
    @users = User.includes(joins).references(joins).where(id: @games.map(&:user_id))
    render :index
  end

  def weekly_stats
    @year = params[:year] || Date.today.year
    @weeks = (1..current_week).to_a
    @week = params[:week] == 'current' ? current_week : params[:week].to_i
    @users = User.includes(user_joins).references(user_joins).all
    @narrowest = Game.includes(game_joins).references(game_joins).where(week: @week, season_year: @year).all.sort_by { |a| a.margin.abs }.first
    @highest_score_game = Game.includes(user: :nicknames).references(user: :nicknames).where(week: @week, season_year: @year).all.find(&:weekly_high_score?)
  end

  private

  def current_week
    # find highest week num in DB
    # old approach causes some issues during week-week transition
    # Time.now.strftime('%U').to_i - 35
    @current_week ||= Game.where(season_year: @year || Date.today.year).order(:week).reverse.first&.week || 0
  end

  def user_joins
    [:games, :opponent_games, nicknames: :votes]
  end

  def game_joins
    %i[user opponent]
  end
end
