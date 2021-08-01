class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[create]

  def create
    @user = User.new(new_user_params)
    if user.save
      redirect_to after_sign_in_path_for(user)
    else
      process_errors(user)
      flash[:register] = true
      redirect_to new_user_session_path
    end
  end

  def show
    @user = User.includes(nicknames: :votes).references(nicknames: :votes).find(params[:user_id])
    @involved_years = @user.historical_games.map(&:season_year).uniq.sort
    @nickname_idx = rand(@user.nicknames.count)
  end

  def edit_password
    @user = User.find(params[:user_id])
    if unauthorized?
      flash[:banner_error] = "Hey! You aren't authorized to edit this account."
      return redirect_back(fallback_location: home_path)
    end
    if user.valid_password?(params[:old_password])
      if params[:password] != params[:password_confirmation]
        flash[:password_confirmation] = 'did not match password'
      else
        if user.update(password: params[:password])
          flash[:password_success] = 'Password updated successfully!'
          sign_in(user, bypass: true)
        else
          flash[:password] = user.errors.full_messages
        end
      end
    else
      flash[:old_password] = 'Invalid credentials'
    end
    redirect_back(fallback_location: home_path)
  end

  def edit_settings
    @user = User.find(params[:user_id])
    if unauthorized?
      flash[:banner_error] = "Hey! You aren't authorized to edit this account."
      return redirect_back(fallback_location: home_path)
    end
    @user.update(settings_params)

    redirect_back(fallback_location: home_path)
  end

  private

  attr_reader :user

  def unauthorized?
    @user.id != current_user[:id]
  end

  def settings_params
    {
      newsletter: params[:newsletter] == 'on',
      podcast_flag: params[:podcast_flag] == 'on'
    }
  end

  def new_user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
