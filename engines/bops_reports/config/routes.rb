# frozen_string_literal: true

BopsReports::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
  resources :planning_applications, param: :reference, only: %i[show] do
    scope module: :planning_applications do
      resources :recommendations, only: %i[new create update edit]
    end
  end
end
