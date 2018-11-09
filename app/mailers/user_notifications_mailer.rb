class UserNotificationsMailer < ApplicationMailer
  default :from => 'lynchpin@westhoochington.com'

  def send_signup_email(user)
    @user = user
    mail( :to => @user.email,
    :subject => 'Welcome to Westhoochington.com, you cuck bastard.' )
  end
end
