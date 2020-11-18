# frozen_string_literal: true

Rails.application.routes.draw do
  # this match is an example on how we could constraint access to subdomain X. It needs to be placed before root.
  # match '', to: "planning_applications#index", :via => [:get, :post], defaults: { q: "exclude_others" }, constraints: lambda { |r| r.subdomain.present? && r.subdomain != 'www'}
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  devise_for :users

  resources :planning_applications, only: %i[show index edit update] do
    resources :decisions, only: %i[new create edit update show]

    resources :drawings, only: %i[index new create] do
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
      resources :planning_applications, only: %i[index]
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
