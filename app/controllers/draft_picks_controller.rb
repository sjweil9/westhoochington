class DraftPicksController < ApplicationController
  def index
    @users = User.includes(index_inclusions).references(index_inclusions).all
  end

  private

  def index_inclusions
    [:nicknames, :calculated_stats, :first_round_picks, :draft_picks]
  end
end
