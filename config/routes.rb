# frozen_string_literal: true

# require "rswag-api"

Rails.application.routes.draw do
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  devise_for :users
  mount Rswag::Api::Engine => "/api-docs"
  mount Rswag::Ui::Engine => "api-docs"

  resources :planning_applications, only: %i[show index edit update] do
    member do
      put :assess
      put :determine
    end
    resources :decisions, only: %i[new create edit update show]

    resources :drawings, only: %i[index new create edit update] do
      get :edit_numbers, on: :collection
      put :update_numbers, on: :collection

      get :archive
      get :confirm

      post :confirm_new, on: :collection

      post :validate_step
    end
  end

  namespace :api do
    namespace :v1 do
      resources :planning_applications, only: %i[index create]
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
