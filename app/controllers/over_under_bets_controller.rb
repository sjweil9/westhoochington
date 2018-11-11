class OverUnderBetsController < ApplicationController
  def create_over
    over_under_bet = OverUnderBet.new(over_under_params.merge(over: true))
    process_errors(over_under_bet) unless over_under_bet.save
    redirect_to over_unders_path
  end

  def create_under
    over_under_bet = OverUnderBet.new(over_under_params.merge(over: false))
    process_errors(over_under_bet) unless over_under_bet.save
    redirect_to over_unders_path
  end

  private

  def over_under_params
    params.permit(:line_id).merge(user_id: current_user[:id])
  end
end
