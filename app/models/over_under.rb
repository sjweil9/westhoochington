class OverUnder < ApplicationRecord
  belongs_to :user

  has_many :lines

  def completed?
    return false unless completed_date

    completed_date < Time.zone.now
  end
end
