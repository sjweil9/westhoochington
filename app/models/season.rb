class Season < ApplicationRecord
  belongs_to :user

  def championship?
    playoff_rank.to_i == 1
  end

  def regular_season_win?
    regular_rank.to_i == 1
  end

  def playoff_appearance?
    regular_rank.to_i <= 4
  end
end
