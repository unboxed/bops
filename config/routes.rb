# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  devise_for :users

  resources :planning_applications, only: %i[show index edit update] do
    resources :decisions, only: %i[new create edit update show]

    resources :drawings, only: %i[index new create] do
      # Numbering
      # /planning_applications/1/drawings/edit_numbers

      # /planning_applications/1/drawings/2/numbers/edit  ?

      # /planning_applications/1/edit_drawing_numbers  ?
      get :edit_numbers, on: :collection
      put :update_numbers, on: :collection

      # Archiving

      # /planning_applications/1/drawings/1/archive
      # /planning_applications/1/drawings/1/confirm
      # /planning_applications/1/drawings/1/validate_step

      # /planning_applications/1/drawings/1/archive/new
      # /planning_applications/1/drawings/1/archive/new/confirm
      # /planning_applications/1/drawings/1/archive/new/validate_step

      get :archive
      get :confirm
      post :validate_step

      # Upload - should this be on collection or something else?

      # planning_applications/1/drawing_upload/new
      # planning_applications/1/drawing_upload/confirm_new
      # planning_applications/1/drawing_upload/create

      post :confirm, on: :new
      # /planning_applications/1/drawings/1  ?
    end
  end

  namespace :api do
    namespace :v1 do
      resources :planning_applications, only: %i[index]
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
