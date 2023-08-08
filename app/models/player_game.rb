class PlayerGame < ApplicationRecord
  belongs_to :player
  belongs_to :user
  belongs_to :game

  scope :lineup_order, -> { order(Arel.sql("array_position(ARRAY['QB', 'RB', 'WR', 'TE', 'FLEX', 'DST', 'K', 'BN']::varchar[], lineup_slot)")) }
  scope :active, -> { where(active: true) }
end
