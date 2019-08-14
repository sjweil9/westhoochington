class PodcastsController < ApplicationController
  before_action :set_s3_direct_post, only: [:index]

  def create
    redirect_to podcasts_path
  end
end
