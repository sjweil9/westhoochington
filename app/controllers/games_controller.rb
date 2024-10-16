class GamesController < ApplicationController
  def index
    @year = params[:year] || most_recent_year
    @week = params[:week] || 'season'
    return weekly if @week && @week != 'season'

    @week = nil
    @games = Game.includes(game_joins).references(game_joins).where(season_year: @year)
    @users = User.includes(user_joins).references(user_joins).where(id: @games.map(&:user_id))
    @playoffs = @games.any?(&:playoff?)
    @completed = Season.find_by(season_year: @year)&.completed?
    if @year.to_i >= 2018
      @faab = FaabStat.find_or_create_by(season_year: @year)
      player_ids = %w[biggest_load narrowest_fail biggest_overpay most_impactful most_impactful_ppg most_impactful_ppd].reduce([]) do |memo, type|
        memo + (@faab.send(type)&.map { |trans| trans['player_id'] } || [])
      end
      @players = Player.where(id: player_ids).all.reduce({}) do |memo, player|
        memo.merge(player.id.to_s => player)
      end
    end
    @season_schedules = @users.map do |user|
      user.calculated_stats.schedule_stats.detect { |hash| hash["year"].to_i == @year.to_i }&.merge(user: user)&.with_indifferent_access
    end.flatten.compact
    render :index
  end

  def weekly
    @season = Season.find_by(season_year: @year) || Season.new(season_year: @year)
    @week = @week.to_i
    @week = @year.to_i >= 2019 && @year.to_i < 2021 && (@season&.two_game_playoff? || @season.nil?) && [14, 16].include?(@week) ? @week - 1 : @week
    @week = @year.to_i >= 2021 && (@season&.two_game_playoff? || @season.nil?) && [15, 17].include?(@week) ? @week - 1 : @week
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

  def most_recent_year
    ActiveRecord::Base.connection.execute("SELECT MAX(season_year) FROM games;").values.flatten.first
  end

  def user_joins
    [:"calculated_stats_#{@year}"]
  end

  def game_joins
    []
  end
end
