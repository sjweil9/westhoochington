class SessionsController < ApplicationController
  def create
    @user = User.find_by(email: login_params[:email])
    if user&.authenticate(login_params[:password])
      redirect_to home_path
    else
      process_errors(user)
      redirect_to new_user_session_path
    end
  end

  private

  attr_reader :user

  def login_params
    params.require(:user).permit(:email, :password)
  end
end
