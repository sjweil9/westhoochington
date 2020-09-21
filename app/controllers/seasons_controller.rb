class SeasonsController < ApplicationController
  def index
    @users = User.includes(user_joins).references(user_joins).all
    @gls = GameLevelStat.first
  end

  private

  def user_joins
    [:calculated_stats]
  end
end
