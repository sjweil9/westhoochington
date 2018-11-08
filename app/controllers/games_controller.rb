class GamesController < ApplicationController
  def index
    @users = User.includes(:games, :nicknames).references(:games, :nicknames).all
  end
end
