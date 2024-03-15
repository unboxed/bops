# frozen_string_literal: true

require "sidekiq/web"

BopsConfig::Engine.routes.draw do
  root to: redirect("dashboard")

  authenticate :user, ->(u) { u.global_administrator? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  resource :dashboard, only: %i[show]

  resources :application_types do
    scope module: "application_types" do
      resource :status, only: %i[edit update]
      resource :determination_period, only: [:edit, :update]
    end
  end

  resources :users, except: %i[show destroy] do
    get :resend_invite, on: :member
  end
end
