class NewsletterMessagesController < ApplicationController
  def new
    @categories = [
      { key: 'high_score', label: 'High Score' },
      { key: 'narrowest', label: 'Narrowest Cucking' },
      { key: 'biggest', label: 'Biggest T-Bagging' },
      { key: 'overperformer', label: 'Overperformer' },
      { key: 'outprojector', label: 'Projections, Schmrojections' }
    ]
  end

  def create

  end
end