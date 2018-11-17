class GamesController < ApplicationController
  def index
    @users = User.includes(user_joins).references(user_joins).all
  end

  def weekly_stats
    @weeks = (1..current_week).to_a
    @week = params[:week] == 'current' ? current_week : params[:week].to_i
    @users = User.includes(user_joins).references(user_joins).all
    @narrowest = Game.includes(game_joins).references(game_joins).where(week: @week).all.sort_by { |a| a.margin.abs }.first
    @highest_score_game = Game.includes(user: :nicknames).references(user: :nicknames).where(week: @week).all.find(&:weekly_high_score?)
  end

  private

  def current_week
    # find highest week num in DB
    # old approach causes some issues during week-week transition
    # Time.now.strftime('%U').to_i - 35
    Game.order(:week).reverse.first.week
  end

  def user_joins
    [{ games: { opponent: :games } }, :opponent_games, :nicknames]
  end

  def game_joins
    %i[user opponent]
  end
end
