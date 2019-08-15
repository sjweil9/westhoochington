class PodcastsController < ApplicationController
  before_action :set_s3_direct_post, only: [:index]

  def create
    podcast = Podcast.new(new_podcast_params)
    process_errors(podcast) unless podcast.save

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
end
