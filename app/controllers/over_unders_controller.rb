class OverUndersController < ApplicationController
  def index
    @over_unders =
      OverUnder
        .joins(user: :nicknames)
        .includes(lines: { user: { nicknames: :votes }, under_bets: :user, over_bets: { user:  { nicknames: :votes } } })
        .references(lines: { user: { nicknames: :votes }, under_bets: :user, over_bets: { user: { nicknames: :votes } } })
        .all
  end

  def create
    @over_under = OverUnder.new(new_over_under_params)
    process_errors(over_under) unless over_under.save
    redirect_to over_unders_path
  end

  private

  attr_reader :over_under

  def new_over_under_params
    params.require(:over_under).permit(:description, :completed_date).merge(user_id: current_user[:id])
  end
end
