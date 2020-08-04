# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  devise_for :users

  resources :planning_applications, only: %i[show index edit update] do
    resources :decisions, only: %i[new create edit update]


    resources :drawings, only: %i[index new create] do
      get :archive
      get :confirm

      post :confirm_new, on: :collection

      post :validate_step
    end
  end

  namespace :api do
    namespace :v1 do
      resources :planning_applications, only: %i[index]
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
