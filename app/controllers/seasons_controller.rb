class SeasonsController < ApplicationController
  def index
    @users = User.includes(user_joins).references(user_joins).all
    @gls = GameLevelStat.first
    @faab = FaabStat.find_by(season_year: 'alltime')
    player_ids = %w[biggest_load narrowest_fail biggest_overpay most_impactful most_impactful_ppg].reduce([]) do |memo, type|
      memo + @faab.send(type).map { |trans| trans['player_id'] }
    end
    @players = Player.where(id: player_ids).all.reduce({}) do |memo, player|
      memo.merge(player.id.to_s => player)
    end
  end

  private

  def user_joins
    [:calculated_stats]
  end
end
