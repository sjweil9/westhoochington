class DraftPicksController < ApplicationController
  def index
    @users = User.includes(index_inclusions).references(index_inclusions).all
    @users_pick_distribution = @users.map do |user|
      {
        nickname: user.random_nickname,
        pick_distribution: pick_distribution_with_colors(user)
      }
    end
  end

  private

  def index_inclusions
    [:nicknames, :calculated_stats, :first_round_picks, :draft_picks]
  end

  def pick_distribution_with_colors(user)
    user.calculated_stats.draft_stats["pick_distribution"].reduce({}) do |memo, (pick_number, hash)|
      color = "green-bg" if (@users - [user]).all? { |u| u.picks_at(pick_number) <= user.picks_at(pick_number) }
      memo.merge(pick_number.to_s => {
        count: hash["count"],
        color: color
      })
    end
  end
end
