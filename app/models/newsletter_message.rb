class NewsletterMessage < ApplicationRecord
  belongs_to :user

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
end
