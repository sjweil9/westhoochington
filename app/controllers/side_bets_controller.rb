class SideBetsController < ApplicationController
  def index
    @side_bets =
      SideBet
        .joins(user: :nicknames)
        .includes(side_bet_acceptances: { user: :nicknames })
        .references(side_bet_acceptances: { user: :nicknames })
        .all
  end

  def create
    side_bet = SideBet.new(new_bet_params)
    process_errors(side_bet) unless side_bet.save
    redirect_to side_hustles_path
  end

  def update
    side_bet = SideBet.find(params[:side_bet_id])
    side_bet.process_update(params[:status]) if side_bet.present?
    redirect_to side_hustles_path
  end

  def accept
    acceptance = SideBetAcceptance.new(accept_bet_params)
    process_errors(acceptance) unless acceptance.save
    redirect_to side_hustles_path
  end

  private

  def accept_bet_params
    {
      user_id: current_user[:id],
      side_bet_id: params[:side_bet_id],
    }
  end

  def new_bet_params
    params.require(:side_bet).permit(:amount, :terms, :max_takers).merge(user_id: current_user[:id])
  end
end