class DraftPicksController < ApplicationController
  def index
    @users = User.includes(index_inclusions).references(index_inclusions).all
    @users_pick_distribution = @users.map do |user|
      {
        nickname: user.random_nickname,
        pick_distribution: pick_distribution_with_colors(user)
      }
    end
    @users_ppg_by_round = @users.map do |user|
      {
        nickname: user.random_nickname,
        ppg_by_round: ppg_by_round_with_colors(user)
      }
    end
  end

  private

  def index_inclusions
    [:calculated_stats, :first_round_picks, :draft_picks, nicknames: :votes]
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

  def ppg_by_round_with_colors(user)
    user.calculated_stats.draft_stats["ppg_by_round"].reduce({}) do |memo, (round_number, hash)|
      color = "green-bg" if (@users - [user]).all? { |u| u.ppg_for_round(round_number) <= user.ppg_for_round(round_number) }
      color = "red-bg" if (@users - [user]).all? { |u| u.ppg_for_round(round_number) >= user.ppg_for_round(round_number) }
      memo.merge(round_number.to_s => {
        average: hash["average"],
        color: color,
        players: hash["players"]
      })
    end
  end
end
