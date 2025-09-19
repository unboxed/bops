# frozen_string_literal: true

BopsConsultees::Engine.routes.draw do
  root to: redirect("planning_applications")

  get :dashboard, to: redirect("planning_applications")
  resources :planning_applications, param: :reference, only: %i[index show] do
    resource :consultee_response, only: :create
    post :resend_link, on: :member
  end
end
