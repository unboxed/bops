# frozen_string_literal: true

# require "rswag-api"

require "sidekiq/web"

Rails.application.routes.draw do
  root to: "planning_applications#index"

  mount Rswag::Ui::Engine => "api-docs"

  authenticate :user, ->(u) { u.administrator? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  devise_scope :user do
    get "setup", to: "users/sessions#setup", as: "setup"
    get "two_factor", to: "users/sessions#two_factor", as: "two_factor"
    get "resend_code", to: "users/sessions#resend_code", as: "resend_code"
  end

  defaults format: "json" do
    get "/os_places_api",
        to: "os_places_api#index",
        as: "os_places_api_index"

    post "/search_addresses_by_polygon",
         to: "os_places_api#search_addresses_by_polygon",
         as: "search_addresses_by_polygon"
  end

  resources :users, only: %i[new create edit update]

  resources :planning_applications, only: %i[index show new edit create update] do
    resource :assessment_report_download, only: :show
    resources :consultees, only: %i[create destroy edit update]
    resource(:consistency_checklist, only: %i[new create edit update show])
    resource :review_assessment_details, only: %i[show edit update]

    resources :policy_classes, except: %i[index] do
      get :part, on: :new

      resources :policies, only: [] do
        resources :comments, only: %i[create update]
      end
    end

    resources :immunity_details, only: [] do
      resources :evidence_groups do
        resources :comments, only: %i[create]
      end
    end

    resources :recommendations, only: %i[new create update]
    resource :recommendations, only: %i[edit]

    member do
      get :confirm_validation
      patch :validate
      patch :invalidate
      get :submit_recommendation
      get :view_recommendation
      patch :submit
      patch :withdraw_recommendation
      patch :assess
      get :edit_public_comment
      get :publish
      patch :determine
      get :decision_notice
      get :validation_notice
      get :validation_decision
      get :validation_documents
      patch :validate_documents
      post :clone
      get :make_public
    end

    resource :constraints, only: %i[show update]

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

    resource :planning_history, only: :show

    resource :legislation, only: %i[show update]

    scope module: :planning_applications do
      resources :notes, only: %i[index create]

      resources :validation_tasks, only: :index

      resources :assessment_tasks, only: :index

      resources :assess_immunity_detail_permitted_development_rights, only: %i[new create]
      resource :assess_immunity_detail_permitted_development_right, only: %i[show edit update]

      resources :review_tasks, only: :index

      resources :review_policy_classes, only: %i[edit update show]

      resources :assessment_details, only: %i[new edit create show update]

      resources :immunity_details, only: %i[new create edit update show] do
        resources :evidence_groups do
          resources :comments, only: %i[update]
        end
      end

      resources :consultations do
        post :send_neighbour_letters
        resources :neighbour_responses, only: %i[new index create edit update]
        resources :redact_neighbour_responses, only: %i[edit update]
        resources :site_visits, only: %i[index new create edit show update]
      end

      resource :consultation_neighbour_addresses, only: %i[create]

      resources :site_notices

      resources :review_immunity_details, only: %i[edit update show]

      resources :review_local_policies, only: %i[edit update show]

      resources :permitted_development_rights, only: %i[new create edit update show]
      resource :cil_liability, only: %i[edit update], controller: :cil_liability

      resources :review_immunity_enforcements, only: %i[show edit update]

      resources :review_permitted_development_rights, only: %i[show edit update]

      resources :review_documents, only: %i[index] do
        patch :update, on: :collection
      end

      resource :withdraw_or_cancel, only: %i[show update]

      resources :assign_users, only: %i[index] do
        patch :update, on: :collection
      end

      resources :press_notices, only: %i[new create show update]
      resources :confirm_press_notices, only: %i[edit update]

      resources :local_policies, only: %i[show new edit create update]
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
        resources :neighbour_responses, only: :create
      end

      resources :local_authorities, only: %i[show], param: :subdomain

      resources :documents, only: :show do
        get :tags, on: :collection
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
end
