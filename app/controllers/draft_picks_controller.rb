class DraftPicksController < ApplicationController
  def index
    @users = User.includes(index_inclusions).references(index_inclusions).all
  end

  private

  def index_inclusions
    [:calculated_stats, :first_round_picks, :draft_picks, nicknames: :votes]
  end
end
