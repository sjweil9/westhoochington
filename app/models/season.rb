class Season < ApplicationRecord
  belongs_to :user

  (2012..Date.today.year).each do |year|
    define_method("#{year}?") { season_year.to_i == year.to_i }
  end

  def championship?
    playoff_rank.to_i == 1
  end

  def second_place?
    playoff_rank.to_i == 2
  end

  def sacko?
    playoff_rank.to_i == Season.where(season_year: season_year).maximum(:playoff_rank).to_i
  end

  def regular_season_win?
    regular_rank.to_i == 1
  end

  def playoff_appearance?
    regular_rank.to_i <= 4
  end

  def two_game_playoff?
    season_year.to_i >= 2015
  end

  def playoff_week?(week)
    return week > 14 if season_year < 2015
    return week >= 14 if season_year < 2018

    week >= 13
  end

  def yahoo?
    season_year.to_i < 2015
  end

  def espn?
    season_year.to_i >= 2015
  end

  def playoffs_started?
    return true if completed?

    current_week = Time.now.strftime('%U').to_i - 35
    playoff_week?(current_week)
  end

  def completed?
    return true if season_year < Date.today.year

    current_week = Time.now.strftime('%U').to_i - 35
    current_week > 16
  end
end
