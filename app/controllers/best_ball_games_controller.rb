class BestBallGamesController < ApplicationController
  def index
    @year = params[:year] || most_recent_year
    @week = params[:week] == "season" ? nil : params[:week]&.to_i
    @possible_years = BestBallLeague.pluck(:season_year).uniq.sort
    if @week
      @leagues = BestBallLeague.where(season_year: most_recent_year).all
      @games = hash_by_league_id(BestBallGame.where(best_ball_league_id: @leagues.map(&:id), week: @week).includes(best_ball_includes).all)
      if @games.all?(&:blank?)
        return render :oops
      end
    else
      @leagues = BestBallLeague.where(season_year: most_recent_year).all
      @games = hash_by_league_id(BestBallGame.where(best_ball_league_id: @leagues.map(&:id)).includes(best_ball_includes).all)
      @league_players = @leagues.reduce({}) do |memo, league|
        memo[league.id.to_s] = league.best_ball_league_users.includes(user: :nicknames).references(user: :nicknames).order(total_points: :desc).map do |league_user|
          {
            user_id: league_user.user_id,
            user_nickname: league_user.user.random_nickname,
            total_points: league_user.total_points,
            overall_lineup: overall_lineup_for(league_user, @games[league.id.to_s])
          }
        end
        memo
      end
    end
  end

  private

  def most_recent_year
    ActiveRecord::Base.connection.execute("SELECT MAX(season_year) FROM best_ball_leagues;").values.flatten.first
  end

  def best_ball_includes
    [user: :nicknames, lineup_ordered_players: :player]
  end

  def hash_by_league_id(games)
    games.reduce({}) do |memo, game|
      memo[game.best_ball_league_id.to_s] ||= []
      memo[game.best_ball_league_id.to_s] << game
      memo
    end
  end

  def overall_lineup_for(league_user, games)
    relevant_games = games.select { |g| g.user_id == league_user.user_id }
    all_players = relevant_games.reduce({}) do |memo, game|
      memo[game.week.to_s] ||= []
      memo[game.week.to_s] += game.lineup_ordered_players
      memo
    end
    player_map = all_players.reduce({ QB: [], RB: [], WR: [], TE: [], FLEX: [], SUPER_FLEX: [], BN: [] }) do |memo, (week, game_players)|
      game_players.each do |game_player|
        existing_player = memo[game_player.position.to_sym].detect { |p| p["name"] == game_player.player.name }
        if existing_player
          existing_player["points"] += game_player.total_points
          existing_player["weeks"] << week unless existing_player["weeks"].include?(week)
        else
          memo[game_player.position.to_sym] << {
            name: game_player.player.name,
            position: game_player.position,
            points: game_player.total_points,
            weeks: [week]
          }.stringify_keys
        end
      end
      memo
    end
    final_result = []
    %i[QB RB WR TE FLEX SUPER_FLEX].each do |position|
      sorted = player_map[position].sort_by { |p| -p["points"] }
      final_result += sorted
    end
    final_result
  end
end
