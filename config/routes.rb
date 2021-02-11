# frozen_string_literal: true

# require "rswag-api"

Rails.application.routes.draw do
  resources :site_visits
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  devise_for :users
  mount Rswag::Ui::Engine => "api-docs"

  resources :planning_applications, only: %i[show index edit] do
    member do
      get :assign
      patch :assign
      patch :assess
      patch :determine
      patch :cancel
      patch :validate_documents
      get :cancel_confirmation
    end
    resources :decisions, only: %i[new create edit update show]

    resources :documents, only: %i[index new create edit update] do
      get :archive
      get :confirm

      post :validate_step
    end
  end

  namespace :api do
    namespace :v1 do
      resources :planning_applications, only: %i[index create show] do
        member do
          get :decision_notice
        end
        resources :documents, only: %i[show]
      end
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
