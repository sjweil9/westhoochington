class DraftPick < ApplicationRecord
  belongs_to :user
  belongs_to :player

  validates :league_platform, :drafted_league_platform, inclusion: { in: %w[espn sleeper].freeze }
  validates :draft_type, inclusion: { in: %w[auction snake].freeze }

  validates :draft_id, presence: true, if: -> { sleeper? }
  validates :bid_amount, :overall_pick_number, presence: true, if: -> { auction? }
  validates :overall_pick_number, :round_number, :round_pick_number, presence: true, if: -> { snake? }

  def auction?
    draft_type == "auction".freeze
  end

  def snake?
    draft_type == "snake".freeze
  end

  def sleeper?
    drafted_league_platform == "sleeper".freeze
  end

  def espn?
    drafted_league_platform == "espn".freeze
  end

  def draft_link
    case drafted_league_platform
    when "sleeper" then "https://sleeper.app/draft/nfl/#{draft_id}"
    when "espn" then "https://fantasy.espn.com/football/league/draftrecap?seasonId=#{season_year}&leagueId=#{drafted_league_id}"
    end
  end
end
