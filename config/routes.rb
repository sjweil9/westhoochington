Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'over_unders#index', as: 'home'

  post '/users', to: 'users#create', as: 'register'
  post '/users/:user_id/nicknames', to: 'nicknames#create', as: 'create_nickname'

  post '/sessions', to: 'sessions#create', as: 'login'

  get '/side_bets', to: 'side_bets#index', as: 'side_hustles'
  post '/side_bets', to: 'side_bets#create', as: 'propose_bet'
  post '/side_bets/:side_bet_id/acceptances', to: 'side_bets#accept', as: 'accept_side_bet'
  patch '/side_bets/:side_bet_id/status/:status', to: 'side_bets#update', as: 'complete_side_bet'

  post '/over_unders', to: 'over_unders#create', as: 'propose_over_under'

  post '/over_unders/:over_under_id/lines', to: 'lines#create', as: 'propose_line'

  post '/lines/:line_id/over_bets', to: 'over_under_bets#create_over', as: 'bet_over'
  post '/lines/:line_id/under_bets', to: 'over_under_bets#create_under', as: 'bet_under'

  devise_for :users

  # put this after devise because of /users/sign_in
  get '/users/:user_id', to: 'users#show', as: 'user_profile'
end
