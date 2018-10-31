class OverUnder < ApplicationRecord
  belongs_to :user

  has_many :lines
end
