Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'over_unders#index', as: 'home'

  post '/users', to: 'users#create', as: 'register'

  # post '/sessions', to: 'sessions#create', as: 'login'

  post '/over_unders', to: 'over_unders#create', as: 'propose_over_under'

  devise_for :users
end
