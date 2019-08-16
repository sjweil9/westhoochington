class PodcastsController < ApplicationController
  before_action :set_s3_direct_post, only: [:index]

  def create
    podcast = Podcast.new(new_podcast_params)
    if params[:send_email] == 'true' && valid_email_params?
      send_email_blast(podcast)
    elsif params[:send_email] == 'true' && !valid_email_params?
      process_email_errors
      return redirect_to podcasts_path
    end

    if podcast.save
      flash[:banner_success] = "Podcast successfully uploaded."
    else
      process_errors(podcast)
    end

    redirect_to podcasts_path
  end

  def index
    @podcasts = Podcast.includes(user: :nicknames).references(user: :nicknames).all.sort_by(&:week)
    @years = @podcasts.map(&:year).uniq
  end

  private

  def new_podcast_params
    params.permit(:week, :year, :file_path, :title).merge(user_id: current_user[:id])
  end

  def valid_email_params?
    params[:subject].present? && params[:body].present?
  end

  def process_email_errors
    flash[:subject] = "Provide a fucking subject, numbnuts." unless params[:subject].present?
    flash[:body] = "You're really gonna send an empty ass email?" unless params[:body].present?
  end

  def send_email_blast(podcast)
    UserNotificationsMailer.send_podcast_blast(params[:subject], params[:body], podcast.download_url(604800)).deliver
  end
end
