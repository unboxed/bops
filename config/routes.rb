# frozen_string_literal: true

# require "rswag-api"

Rails.application.routes.draw do
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  devise_for :users
  mount Rswag::Ui::Engine => "api-docs"

  resources :planning_applications, only: %i[index show new edit create update] do
    resources :policy_classes, except: %i[index edit] do
      get :part, on: :new
    end

    member do
      get :assign
      patch :assign
      get :validate_form
      get :confirm_validation
      patch :validate
      patch :invalidate
      get :recommendation_form
      patch :recommend
      get :submit_recommendation
      get :view_recommendation
      patch :assess
      get :review_form
      patch :review
      get :publish
      patch :determine
      patch :cancel
      get :edit_constraints_form
      patch :edit_constraints
      get :cancel_confirmation
      get :decision_notice
      get :draw_sitemap
      patch :update_sitemap
      get :validation_notice
    end

    resources :documents, only: %i[index new create edit update] do
      get :archive

      patch :confirm_archive
      patch :unarchive
    end

    resources :audits, only: :index
    resources :validation_requests, only: %i[index new create]
    resources :description_change_validation_requests, only: %i[new create]
    resources :replacement_document_validation_requests, only: %i[new create]
    resources :other_change_validation_requests, only: %i[new create show]
    resources :additional_document_validation_requests, only: %i[new create]
    resources :other_change_validation_requests, only: %i[new create show]
    resources :red_line_boundary_change_validation_requests, only: %i[new create show]
  end

  namespace :api do
    namespace :v1 do
      resources :planning_applications, only: %i[index create show] do
        member do
          get :decision_notice
        end
        resources :validation_requests, only: :index
        resources :description_change_validation_requests, only: :update
        resources :replacement_document_validation_requests, only: :update
        resources :additional_document_validation_requests, only: :update
        resources :documents, only: %i[show]
        resources :other_change_validation_requests, only: :update
        resources :red_line_boundary_change_validation_requests, only: :update
      end
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }
end
