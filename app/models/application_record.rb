class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def to_currency(amount)
    ActionController::Base.helpers.number_to_currency(amount)
  end
end
