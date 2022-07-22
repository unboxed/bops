# frozen_string_literal: true

# require "rswag-api"

Rails.application.routes.draw do
  root to: "planning_applications#index", defaults: { q: "exclude_others" }

  mount Rswag::Ui::Engine => "api-docs"

  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  devise_scope :user do
    get "setup", to: "users/sessions#setup", as: "setup"
    get "two_factor", to: "users/sessions#two_factor", as: "two_factor"
    get "resend_code", to: "users/sessions#resend_code", as: "resend_code"
  end

  resources :users, only: %i[new create edit update]

  resources :planning_applications, only: %i[index show new edit create update] do
    resources :policy_classes, except: %i[index edit] do
      get :part, on: :new
    end

    member do
      get :assign
      patch :assign
      get :confirm_validation
      patch :validate
      patch :invalidate
      get :recommendation_form
      patch :recommend
      get :submit_recommendation
      get :view_recommendation
      patch :submit
      patch :withdraw_recommendation
      patch :save_assessment
      patch :assess
      get :review_form
      get :edit_public_comment
      patch :review
      get :publish
      patch :determine
      patch :cancel
      get :close_or_cancel_confirmation
      get :decision_notice
      get :validation_notice
      get :validation_decision
      get :validation_documents
      patch :validate_documents
    end

    resource :constraints, only: %i[show edit update] do
      patch :check
    end

    resource :fee_items, only: %i[show] do
      patch :validate
    end

    resource :sitemap, only: %i[show edit update] do
      patch :validate
    end

    resources :documents, only: %i[index new create edit update] do
      get :archive

      patch :confirm_archive
      patch :unarchive
    end

    resources :audits, only: :index
    resources :validation_requests, only: %i[index] do
      get :post_validation_requests, on: :collection
    end

    concern :cancel_validation_requests do
      member do
        get :cancel_confirmation

        patch :cancel
      end
    end

    with_options concerns: :cancel_validation_requests do
      resources :additional_document_validation_requests, only: %i[new create edit update destroy]
      resources :other_change_validation_requests, only: %i[new create show edit update destroy]
      resources :red_line_boundary_change_validation_requests, only: %i[new create show edit update destroy]
      resources :replacement_document_validation_requests, only: %i[new create show edit update destroy]
    end

    resources :description_change_validation_requests, only: %i[new create show] do
      patch :cancel
    end

    scope module: :planning_application do
      resources :notes, only: %i[index create]

      resources :validation_tasks, only: :index
    end
  end

  namespace :public, path: "/" do
    resources :planning_guides, only: :index
    resource :planning_guides, only: :show do
      get "/:page", action: "show"
      get "/:type/:page", action: "show"
    end
  end

  namespace :api do
    namespace :v1 do
      resources :planning_applications, only: %i[index create show] do
        member do
          get :decision_notice
        end
        resources :validation_requests, only: :index
        resources :description_change_validation_requests, only: %i[index update show]
        resources :replacement_document_validation_requests, only: %i[index update show]
        resources :additional_document_validation_requests, only: %i[index update show]
        resources :documents, only: %i[show]
        resources :other_change_validation_requests, only: %i[index update show]
        resources :red_line_boundary_change_validation_requests, only: %i[index update show]
      end
    end
  end

  get :healthcheck, to: proc { [200, {}, %w[OK]] }

  resources :local_authorities, only: %i[edit update]

  resource(
    :administrator_dashboard,
    only: %i[show],
    controller: :administrator_dashboard
  )

  resources :searches, only: %i[create]
end
