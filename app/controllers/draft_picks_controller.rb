class DraftPicksController < ApplicationController
  def index
    @users = User.where.not(espn_id: nil).includes(index_inclusions).references(index_inclusions).all
  end

  private

  def index_inclusions
    [:calculated_stats, nicknames: :votes]
  end
end
