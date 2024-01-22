# frozen_string_literal: true

BopsAdmin::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
  resource :profile, only: %i[show edit update]
  resources :users, except: %i[show destroy] do
    get :resend_invite, on: :member
  end
end
