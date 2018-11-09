class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[create]

  def create
    @user = User.new(new_user_params)
    if user.save
      UserNotificationsMailer.send_signup_email(user).deliver
      redirect_to after_sign_in_path_for(user)
    else
      process_errors(user)
      flash[:register] = true
      redirect_to new_user_session_path
    end
  end

  def show
    @user = User.includes(:nicknames).references(:nicknames).find(params[:user_id])
    @nickname_idx = rand(@user.nicknames.count)
  end

  private

  attr_reader :user

  def new_user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
