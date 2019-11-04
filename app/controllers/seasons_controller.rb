class SeasonsController < ApplicationController
  def index
    @users = User.includes(user_joins).references(user_joins).all
  end

  private

  def user_joins
    [:seasons, historical_games: { opponent: { nicknames: :votes } }, nicknames: :votes]
  end
end
