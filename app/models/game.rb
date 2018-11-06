class Game < ApplicationRecord
  belongs_to :user
  belongs_to :opponent, class_name: 'User'
end
