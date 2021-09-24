class DraftPick < ApplicationRecord
  belongs_to :user
  belongs_to :player

  validates :league_platform, inclusion: { in: %w[espn sleeper].freeze }
  validates :draft_type, inclusion: { in: %w[auction snake].freeze }

  store :metadata, accessors: %i[nominating_user_id bid_amount overall_pick_number round_number round_pick_number]

  validates :nominating_user_id, :bid_amount, :overall_pick_number, presence: true, if: -> { auction? }
  validates :overall_pick_number, :round_number, :round_pick_number, presence: true, if: -> { snake? }

  def auction?
    draft_type == "auction".freeze
  end

  def snake?
    draft_type == "snake".freeze
  end
end
