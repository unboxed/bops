# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect("/planning_applications")

  devise_for :users do
    get "/users/sign_out", to: "devise/sessions#destroy"
  end

  resources :planning_applications, only: [:show, :index] do
    resource :policy_evaluation, only: [:show, :update]

    resources :decisions, only: [:new, :create]
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
