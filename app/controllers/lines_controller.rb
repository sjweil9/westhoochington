class LinesController < ApplicationController
  def create
    line = Line.new(new_line_params)
    process_errors(line) unless line.save
    redirect_to home_path
  end

  private

  def new_line_params
    params.permit(:value, :over_under_id).merge(user_id: current_user[:id])
  end
end
