# frozen_string_literal: true

# require "rswag-api"

Rails.application.routes.draw do
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  devise_for :users
  mount Rswag::Ui::Engine => "api-docs"

  resources :planning_applications, only: %i[index show new edit create update] do
    member do
      get :assign
      patch :assign
      get :validate_documents_form
      patch :validate_documents
      get :recommendation_form
      patch :recommend
      get :submit_recommendation
      patch :assess
      get :review_form
      patch :review
      get :publish
      patch :determine
      patch :cancel
      get :cancel_confirmation
      get :decision_notice
    end

    resources :documents, only: %i[index new create edit update] do
      get :archive

      patch :confirm_archive
    end

    resources :audits, only: :index
  end

  namespace :api do
    namespace :v1 do
      resources :planning_applications, only: %i[index create show] do
        member do
          get :decision_notice
        end
        resources :documents, only: %i[show]
      end
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
