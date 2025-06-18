# frozen_string_literal: true

BopsConsultees::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
  resources :planning_applications, param: :reference, only: %i[show] do
    resource :consultee_response, only: :create
    post :resend_link, on: :member
  end
end
