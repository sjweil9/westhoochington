Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'over_unders#index', as: 'home'

  post '/users', to: 'users#create', as: 'register'

  # post '/sessions', to: 'sessions#create', as: 'login'

  post '/over_unders', to: 'over_unders#create', as: 'propose_over_under'

  post '/over_unders/:over_under_id/lines', to: 'lines#create', as: 'propose_line'

  post '/lines/:line_id/over_bets', to: 'over_under_bets#create_over', as: 'bet_over'
  post '/lines/:line_id/under_bets', to: 'over_under_bets#create_under', as: 'bet_under'

  devise_for :users
end
