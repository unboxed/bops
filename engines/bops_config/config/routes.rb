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
      with_options only: %i[edit update] do
        resource :determination_period
        resource :document_tags
        resource :features
        resource :legislation
        resource :status
      end
    end
  end

  resources :legislation, except: %i[show]

  resources :users, except: %i[show destroy] do
    get :resend_invite, on: :member
  end
end
