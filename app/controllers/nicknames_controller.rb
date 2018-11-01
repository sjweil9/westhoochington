class NicknamesController < ApplicationController
  def create
    nickname = Nickname.create(new_nickname_params)
    process_errors(nickname) unless nickname.save
    redirect_back(fallback_location: home_path)
  end

  private

  def new_nickname_params
    params.permit(:name, :user_id)
  end
end
