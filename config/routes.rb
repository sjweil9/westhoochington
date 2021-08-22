Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'games#index', as: 'home'

  get '/rules', to: 'rules#index'

  post '/users', to: 'users#create', as: 'register'
  post '/users/:user_id/nicknames', to: 'nicknames#create', as: 'create_nickname'
  put '/users/:user_id/password', to: 'users#edit_password', as: 'edit_password'
  put '/users/:user_id/settings', to: 'users#edit_settings', as: 'edit_settings'

  post '/sessions', to: 'sessions#create', as: 'login'

  get '/side_bets', to: 'side_bets#index', as: 'side_hustles'
  post '/game_side_bets', to: 'side_bets#create_game_bet', as: 'propose_game_bet'
  post '/side_bets/acceptances/:acceptance_id/confirm_payment_received', to: 'side_bets#confirm_payment_received', as: 'confirm_payment_received'
  post '/side_bets/acceptances/:acceptance_id/mark_payment_sent', to: 'side_bets#mark_payment_sent', as: 'mark_payment_sent'

  post '/season_side_bets', to: 'side_bets#create_season_bet', as: 'propose_season_bet'
  post '/over_under_bets', to: 'side_bets#create_over_under_bet', as: 'propose_over_under_bet'
  post '/weekly_side_bets', to: 'side_bets#create_weekly_bet', as: 'propose_weekly_bet'

  post '/side_bets/:bet_type/:side_bet_id/acceptances', to: 'side_bets#accept_bet', as: 'accept_bet'
  post '/side_bets/:bet_type/:side_bet_id/cancel', to: 'side_bets#cancel', as: 'cancel_bet'

  #patch '/side_bets/:side_bet_id/status/:status', to: 'side_bets#update', as: 'complete_side_bet'
  #post '/side_bets/acceptances/:acceptance_id/mark_as_paid', to: 'side_bets#mark_as_paid', as: 'mark_as_paid'
  get '/side_bets/pending', to: 'side_bets#pending', as: 'pending_bets'
  get '/side_bets/resolved', to: 'side_bets#resolved', as: 'resolved_bets'

  post '/over_unders', to: 'over_unders#create', as: 'propose_over_under'
  get '/over_unders', to: 'over_unders#index', as: 'over_unders'

  post '/over_unders/:over_under_id/lines', to: 'lines#create', as: 'propose_line'

  post '/lines/:line_id/over_bets', to: 'over_under_bets#create_over', as: 'bet_over'
  post '/lines/:line_id/under_bets', to: 'over_under_bets#create_under', as: 'bet_under'

  get '/games', to: 'games#index', as: 'stats'
  get '/hall-of-fame', to: 'seasons#index', as: 'hall_of_fame'

  get '/newsletter-messages', to: 'newsletter_messages#new', as: 'new_newsletter_message'
  post '/newsletter-messages', to: 'newsletter_messages#create', as: 'create_newsletter_message'

  get '/podcasts', to: 'podcasts#index', as: 'podcasts'
  post '/podcasts', to: 'podcasts#create', as: 'upload_podcast'

  post '/nicknames/:nickname_id/upvote', to: 'nicknames#upvote', as: 'nickname_upvote'
  post '/nicknames/:nickname_id/downvote', to: 'nicknames#downvote', as: 'nickname_downvote'

  devise_for :users

  # put this after devise because of /users/sign_in
  get '/users/:user_id', to: 'users#show', as: 'user_profile'
end
