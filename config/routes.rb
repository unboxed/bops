# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect("/planning_applications")

  devise_for :users

  resources :planning_applications, only: [:show, :index, :update]
end
