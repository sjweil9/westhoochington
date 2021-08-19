class Payment < ApplicationRecord
  belongs_to :user

  PAYOUT_MAP = {
    buy_in: 150,
    weekly_payout: 20,
    first_place: 900,
    second_place: 360,
    third_place: 150,
    regular_season_winner: 150
  }.with_indifferent_access

  validate :validate_bet_type

  private

  def validate_bet_type
    return if PAYOUT_MAP.keys.include?(type)

    errors.add(:payment_type, "Not a valid type.")
  end
end

