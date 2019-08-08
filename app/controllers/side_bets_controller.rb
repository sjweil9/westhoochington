class SideBetsController < ApplicationController
  def index
    @side_bets =
      SideBet
        .includes(user: { nicknames: :votes }, side_bet_acceptances: { user: { nicknames: :votes } })
        .references(side_bet_acceptances: { user: { nicknames: :votes } })
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
    side_bet = SideBet.find(params[:side_bet_id])
    validate_open!(side_bet)
    return redirect_to side_hustles_path if flash[:banner_error]

    acceptance = SideBetAcceptance.new(accept_bet_params)
    process_errors(acceptance) unless acceptance.save
    redirect_to side_hustles_path
  end

  def mark_as_paid
    acceptance = SideBetAcceptance.find(params[:acceptance_id])
    validate_unpaid!(acceptance)
    validate_ownership!(acceptance)
    return redirect_to side_hustles_path if flash[:banner_error]

    acceptance.mark_as_paid!
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
    params.require(:side_bet).permit(:amount, :terms, :max_takers, :closing_date).merge(user_id: current_user[:id])
  end

  def validate_open!(side_bet)
    return unless side_bet.completed?

    flash[:banner_error] = "Oops! This bet has already been completed or is past the closing date."
  end

  def validate_unpaid!(acceptance)
    return unless acceptance.paid?

    flash[:banner_error] = "Oops! This bet has already been marked paid."
  end

  def validate_ownership!(acceptance)
    return if (acceptance.won? && acceptance.user_id == current_user[:id]) || (acceptance.lost? && acceptance.side_bet.user_id == current_user[:id])

    flash[:banner_error] = "Oops! You are not authorized to mark this bet as paid, as you were not the winner."
  end

  def validate_creator!(side_bet)
    return if side_bet.user_id == current_user[:id]

    flash[:banner_error] = "Oops! You are not authorized to update this side bet, as you are not the creator."
  end
end
