class NewsletterMessage < ApplicationRecord
  belongs_to :user

  # https://utopia.duth.gr/~pefraimi/research/data/2007EncOfAlg.pdf
  # https://stackoverflow.com/questions/31493673/rails-query-random-records-using-weights
  scope :weighted_random, -> { order("RANDOM() ^ (1.0 / GREATEST(used, 1)) ASC") }

  CATEGORIES = {
    high_score: {
      label: 'High Score',
      variables: %i[player score],
      direction: '>',
      levels: [
        [:crushed, 'Crushed', 180],
        [:very_high, 'Very High', 150],
        [:high, 'High', 130],
        [:medium, 'Medium', 120],
        [:low, 'Low', 0],
      ]
    },
    narrowest: {
      label: 'Narrowest Cucking',
      variables: %i[winner loser margin],
      direction: '<',
      levels: [
        [:very_narrow, 'Very Narrow', 5],
        [:medium, 'Medium', 10],
        [:not_narrow, 'Not Narrow', Float::INFINITY]
      ]
    },
    biggest: {
      label: 'Biggest T-Bagging',
      variables: %i[winner loser margin],
      direction: '>',
      levels: [
        [:very_large, 'Very Large', 50],
        [:large, 'Large', 30],
        [:medium, 'Medium', 10],
        [:small, 'Small', 0]
      ]
    },
    overperformer: {
      label: 'Overperformer',
      variables: %i[player points average],
      direction: '>',
      levels: [
        [:large, 'Large', 30],
        [:medium, 'Medium', 10],
        [:low, 'Low', 0]
      ]
    },
    outprojector: {
      label: 'Projections, Shmrojections',
      variables: %i[player points projected],
      direction: '>',
      levels: [
        [:large, 'Large', 30],
        [:medium, 'Medium', 10],
        [:low, 'Low', 0]
      ]
    }
  }

  COMPARISON_FUNCTIONS = {
    '>' => lambda { |input, threshold| input > threshold },
    '<' => lambda { |input, threshold| input < threshold }
  }

  validate :valid_category, :valid_level, :valid_template_string
  validates_uniqueness_of :template_string
  before_create :set_defaults

  def valid_category
    return if valid_category?

    errors.add(:category, "is invalid: must be one of #{valid_category_descriptions.join(', ')}")
  end

  def valid_category?
    CATEGORIES.key?(category.to_sym)
  end

  def valid_category_descriptions
    CATEGORIES.map { |_k, hash| hash[:label] }
  end

  def valid_level
    return if !valid_category? || valid_level?

    errors.add(:level, "is invalid: must be one of #{valid_level_descriptions.join(', ')}")
  end

  def valid_level?
    CATEGORIES.dig(category.to_sym, :levels).any? { |lvl| lvl[0] == level.to_sym }
  end

  def valid_level_descriptions
    CATEGORIES.dig(category.to_sym, :levels).map { |level| level[1] }
  end

  def valid_template_string
    return if !valid_category? || valid_template_string?

    errors.add(:template_string, "is invalid: must contain variables: #{decorated_variables.join(', ')}")
  end

  def valid_template_string?
    decorated_variables.all? do |var|
      template_string.include?(var)
    end
  end

  def decorated_variables
    CATEGORIES.dig(category.to_sym, :variables).map { |var| "%{#{var}}" }
  end

  def set_defaults
    self.used = 0
  end
end
