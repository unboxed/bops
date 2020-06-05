# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect("/planning_applications")

  devise_for :users do
    get "/users/sign_out", to: "devise/sessions#destroy"
  end

  resources :planning_applications, only: %i[show index edit update] do
    resources :decisions, only: %i[new create edit update]
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
