class SideBetsController < ApplicationController
  def index
    @side_bets =
      SideBet
        .joins(user: :nicknames)
        .includes(side_bet_acceptances: { user: :nicknames })
        .references(side_bet_acceptances: { user: :nicknames })
        .all
  end
end
