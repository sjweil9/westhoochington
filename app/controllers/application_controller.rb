class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :authenticate_user!

  private

  def process_errors(object)
    return unless object&.errors&.messages

    object.errors.messages.each do |tag, message|
      flash[tag] = message
    end
  end
end
