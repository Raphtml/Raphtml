Rails.application.routes.draw do
  root "dashboard#index"

  get  "login",          to: "sessions#new",     as: :login
  get  "auth/callback",  to: "sessions#create",  as: :callback_sessions
  delete "logout",       to: "sessions#destroy", as: :logout

  post "dashboard/sync", to: "dashboard#sync",   as: :sync_dashboard

  resources :activities, only: :index
  resources :reports,    only: :create

  get "up" => "rails/health#show", as: :rails_health_check
end
