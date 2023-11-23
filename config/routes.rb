# frozen_string_literal: true

# require "rswag-api"

require "sidekiq/web"

Rails.application.routes.draw do
  root to: "planning_applications#index"

  mount BopsApi::Engine, at: "/api"
  mount Rswag::Ui::Engine, at: "/api-docs"

  authenticate :user, ->(u) { u.administrator? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    confirmations: "confirmations"
  }

  devise_scope :user do
    get "setup", to: "users/sessions#setup", as: "setup"
    get "two_factor", to: "users/sessions#two_factor", as: "two_factor"
    get "resend_code", to: "users/sessions#resend_code", as: "resend_code"
    patch "/confirmations/confirm_and_set_password", to: "confirmations#confirm_and_set_password"
  end

  defaults format: "json" do
    get "/os_places_api",
      to: "os_places_api#index",
      as: "os_places_api_index"

    post "/search_addresses_by_polygon",
      to: "os_places_api#search_addresses_by_polygon",
      as: "search_addresses_by_polygon"

    scope "/contacts" do
      get "/consultees", to: "contacts#index", defaults: {category: "consultee"}
    end
  end

  resources :users, only: %i[new create edit update]

  resources :planning_applications, except: %i[destroy] do
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

    resources :documents, except: %i[destroy show] do
      get :archive

      patch :confirm_archive
      patch :unarchive
    end

    resources :audits, only: :index

    scope module: :planning_applications do
      resources :assign_users, only: %i[index] do
        patch :update, on: :collection
      end

      resources :confirm_press_notices, only: %i[edit update]
      resources :site_notices
      resources :press_notices, only: %i[new create show update]
      resource :withdraw_or_cancel, only: %i[show update]
      resources :notes, only: %i[index create]

      namespace :assessment do
        resource :report_download, only: :show
        resources :assess_immunity_detail_permitted_development_rights, only: %i[new create]
        resource :assess_immunity_detail_permitted_development_right, only: %i[show edit update]
        resources :assessment_details, except: %i[destroy index]
        resources :tasks, only: :index
        resources :conditions, only: %i[index] do
          get :edit, on: :collection
          patch :update, on: :collection
        end
        resource :consistency_checklist, except: %i[destroy index]

        resources :immunity_details, except: %i[destroy index] do
          resources :evidence_groups do
            resources :comments, only: %i[create update]
          end
        end

        resources :local_policies, except: %i[destroy index]

        resources :permitted_development_rights, except: %i[destroy index]

        resource :planning_history, only: :show

        resources :policy_classes, except: %i[index] do
          get :part, on: :new

          resources :policies, only: [] do
            resources :comments, only: %i[create update]
          end
        end
        resources :recommendations, only: %i[new create update]
        resource :recommendations, only: %i[edit]
      end

      resources :consultees, only: %i[create show] do
        resources :responses, controller: "consultee/responses", except: %i[show destroy]
      end

      namespace :consultee, as: :consultees do
        resources :emails, only: %i[index create]
        resources :responses, only: %i[index]
      end

      resource :consultation, only: %i[show update] do
        resources :neighbour_letters, only: %i[index create update destroy] do
          post :send_letters, on: :collection
        end

        resources :neighbour_responses, except: %i[show destroy]
        resources :redact_neighbour_responses, only: %i[edit update]
        resources :site_visits, except: %i[destroy]
      end

      namespace :validation do
        resources :tasks, only: :index

        resource :cil_liability, only: %i[edit update], controller: :cil_liability

        resource :constraints, only: %i[show update]

        resources :description_change_validation_requests, only: %i[new create show] do
          patch :cancel
        end

        namespace :document, as: :documents do
          resources :redactions, only: %i[index create]
        end

        resource :fee_items, only: %i[show] do
          patch :validate
        end

        resource :sitemap, only: %i[show edit update] do
          patch :validate
        end

        resources :validation_requests, only: %i[index] do
          get :post_validation_requests, on: :collection
        end

        resource :legislation, only: %i[show update]

        concern :cancel_validation_requests do
          member do
            get :cancel_confirmation

            patch :cancel
          end
        end

        with_options concerns: :cancel_validation_requests do
          resources :additional_document_validation_requests, except: %i[index show]
          resources :other_change_validation_requests, except: %i[index]
          resources :red_line_boundary_change_validation_requests, except: %i[index]
          resources :replacement_document_validation_requests, except: %i[index]
        end
      end

      namespace :review do
        resource :assessment_details, only: %i[show edit update]

        resource :conditions, only: %i[show update]

        resources :documents, only: %i[index] do
          patch :update, on: :collection
        end

        resources :immunity_details, only: %i[edit update show]

        resources :immunity_enforcements, only: %i[show edit update]

        resources :local_policies, only: %i[edit update show]

        resources :permitted_development_rights, only: %i[show edit update]

        resources :policy_classes, only: %i[edit update show]

        resources :tasks, only: :index
      end
    end
  end

  namespace :public, path: "/" do
    scope "/planning_guides" do
      get "/", to: "planning_guides#index", as: :planning_guides
      get "/*path", to: "planning_guides#show", as: nil
    end
  end

  namespace :public do
    resources :planning_applications, only: [] do
      member do
        get "decision_notice"
      end
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
