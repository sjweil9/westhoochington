class PodcastsController < ApplicationController
  before_action :set_s3_direct_post, only: [:index]

  def create
    podcast = Podcast.new(new_podcast_params)
    process_errors(podcast) unless podcast.save

    redirect_to podcasts_path
  end

  private

  def new_podcast_params
    params.permit(:week, :year, :file_path).merge(user_id: current_user[:id])
  end
end
