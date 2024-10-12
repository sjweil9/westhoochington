class SeasonsController < ApplicationController
  def index
    # only get users associated to at least one Game (eg not BB-only users like for BB0 in 2023)
    @users = User.includes(user_joins).references(user_joins).where(id: Game.select(:user_id))
    @gls = GameLevelStat.first
    @faab = FaabStat.find_by(season_year: 'alltime')
    player_ids = %w[biggest_load narrowest_fail biggest_overpay most_impactful most_impactful_ppg most_impactful_ppd].reduce([]) do |memo, type|
      memo + @faab.send(type).map { |trans| trans['player_id'] }
    end
    @players = Player.where(id: player_ids).all.reduce({}) do |memo, player|
      memo.merge(player.id.to_s => player)
    end
    @season_schedules = @users.map do |user|
      user.calculated_stats.schedule_stats.map { |hash| hash.merge(user: user).with_indifferent_access }
    end.flatten
  end

  private

  def user_joins
    [:calculated_stats]
  end
end
