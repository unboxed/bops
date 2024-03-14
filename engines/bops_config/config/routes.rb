# frozen_string_literal: true

require "sidekiq/web"

BopsConfig::Engine.routes.draw do
  root to: redirect("dashboard")

  authenticate :user, ->(u) { u.global_administrator? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  resource :dashboard, only: %i[show]

  resources :application_types

  resources :users, except: %i[show destroy] do
    get :resend_invite, on: :member
  end
end
