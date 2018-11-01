class OverUndersController < ApplicationController
  def index
    @over_unders =
      OverUnder
        .joins(user: :nicknames)
        .includes(lines: { user: :nicknames, under_bets: :user, over_bets: { user: :nicknames } })
        .references(lines: { user: :nicknames, under_bets: :user, over_bets: { user: :nicknames } })
        .all
  end

  def create
    @over_under = OverUnder.new(new_over_under_params)
    process_errors(over_under) unless over_under.save
    redirect_to home_path
  end

  private

  attr_reader :over_under

  def new_over_under_params
    params.require(:over_under).permit(:description, :completed_date).merge(user_id: current_user[:id])
  end
end