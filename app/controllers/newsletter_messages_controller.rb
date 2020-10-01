class NewsletterMessagesController < ApplicationController
  def new
  end

  def create
    message = NewsletterMessage.new(message_params)
    process_errors(message) unless message.save
    redirect_to new_newsletter_message_path
  end

  private

  def message_params
    params.permit(:category, :level, :template_string).merge(user_id: current_user[:id])
  end
end