# frozen_string_literal: true

Rails.application.routes.draw do
  extend BopsCore::Routing

  get :healthcheck, to: proc { [200, {}, %w[OK]] }

  devise_subdomain do
    devise_for :users, controllers: {
      sessions: "users/sessions",
      confirmations: "confirmations"
    }

    devise_scope :user do
      get "setup", to: "users/sessions#setup", as: "setup"
      get "two_factor", to: "users/sessions#two_factor", as: "two_factor"
      get "resend_code", to: "users/sessions#resend_code", as: "resend_code"
    end
  end

  local_authority_subdomain do
    root to: "planning_applications#index"

    concern :positionable do |options|
      defaults format: "json" do
        resource :position, {only: %i[update]}.merge(options)
      end
    end

    mount BopsApi::Engine, at: "/api", as: :bops_api
    get "/api-docs(/index)", to: redirect("/api/docs")

    mount BopsAdmin::Engine, at: "/admin", as: :bops_admin

    mount BopsConsultees::Engine, at: "/consultees", as: :bops_consultees

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

      get "/informatives", to: "informatives#index"
      get "/policy/guidance", to: "policy_guidances#index"
      get "/policy/references", to: "policy_references#index"
      get "/requirements", to: "requirements#index"
    end

    resources :planning_applications, param: :reference, except: %i[destroy] do
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
        get :supply_documents
        get :make_public
      end

      resources :documents, except: %i[destroy show] do
        get :archive

        patch :confirm_archive
        patch :unarchive
      end

      resources :audits, only: :index

      scope module: :planning_applications do
        resource :appeal, only: %i[new show create update] do
          resource :validate, only: %i[edit update], controller: "appeals/validates"
          resource :start, only: %i[edit update], controller: "appeals/starts"
          resource :decision, only: %i[edit update], controller: "appeals/decisions"
        end

        resources :assign_users, only: %i[index] do
          patch :update, on: :collection
        end

        resource :additional_services, only: %i[edit update], on: :collection

        resource :press_notice, only: %i[new show create update] do
          resource :confirmation, only: %i[show edit update], controller: "press_notices/confirmations"
          resources :confirmation_requests, only: %i[create], controller: "press_notices/confirmation_requests"
        end

        resources :site_notices do
          resources :confirmation_requests, only: %i[create], controller: "site_notices/confirmation_requests"
        end

        resource :withdraw_or_cancel, only: %i[show update]
        resources :notes, only: %i[index create]

        namespace :assessment do
          root to: "base#index"

          resource :report_download, only: :show
          resources :assess_immunity_detail_permitted_development_rights, only: %i[new create]
          resource :assess_immunity_detail_permitted_development_right, only: %i[show edit update]
          resources :assessment_details, except: %i[destroy index]
          resources :tasks, only: :index
          resources :conditions, except: %i[new show] do
            patch :update, on: :collection
            patch :mark_as_complete, on: :collection
            concerns :positionable, module: :conditions
          end
          resources :pre_commencement_conditions, except: %i[new show] do
            post :confirm, on: :collection
            concerns :positionable, module: :pre_commencement_conditions
          end
          resource :consistency_checklist, except: %i[destroy index]
          resources :consultees, only: %i[index] do
            patch :check, on: :collection
          end
          resource :ownership_certificate, except: %i[destroy index]

          resources :immunity_details, except: %i[destroy index] do
            resources :evidence_groups do
              resources :comments, only: %i[create update]
            end
          end

          resource :permitted_development_rights, only: %i[show edit update]

          namespace :policy_areas do
            resources :parts, only: :index
            resources :policy_classes, except: %i[show]
          end

          resources :site_histories, except: %i[new show] do
            post :confirm, on: :collection
          end

          resources :site_visits, except: %i[destroy]

          resources :meetings, except: %i[edit update destroy]

          resources :heads_of_terms, only: %i[index new] do
            get :edit, on: :collection
            get :edit
            patch :update, on: :collection
          end

          resources :terms, except: %i[new show] do
            post :confirm, on: :collection
            concerns :positionable, module: :terms
          end

          resources :recommendations, only: %i[new create update]
          resource :recommendations, only: %i[edit]

          resource :considerations, only: %i[create show edit update] do
            resources :items, only: %i[edit update destroy], module: :considerations do
              concerns :positionable
            end
          end

          resource :informatives, only: %i[create show edit update] do
            resources :items, only: %i[edit update destroy], module: :informatives do
              concerns :positionable
            end
          end
        end

        resources :consultees, only: %i[index create show new] do
          resources :responses, controller: "consultee/responses", except: %i[show destroy]
        end

        namespace :consultee, as: :consultees do
          resources :emails, only: %i[index create]
          resources :responses, only: %i[index]
          resource :assign_constraint, only: %i[create]
        end

        resource :consultation, only: %i[show edit update] do
          resources :neighbours, only: %i[index create update destroy]

          resources :neighbour_letters, only: %i[index update destroy] do
            post :send_letters, on: :collection
          end
          resources :neighbour_letter_batches, only: [:index]

          resources :neighbour_responses, except: %i[show destroy]
          resources :redact_neighbour_responses, only: %i[edit update]
        end

        namespace :validation do
          root to: "base#index"

          resources :tasks, only: :index

          resource :cil_liability, only: %i[edit update], controller: :cil_liability

          resource :environment_impact_assessment, only: %i[new create edit show update]

          resource :reporting_type, only: %i[show edit update]

          resources :constraints, only: %i[index create destroy] do
            patch :update, on: :collection
          end

          resource :documents, only: %i[edit update]

          namespace :document, as: :documents do
            resources :redactions, only: %i[index create]
          end

          resource :ownership_certificate do
            patch :validate
          end

          resource :description_changes, only: %i[show] do
            patch :validate
          end

          resource :fee_items, only: %i[show] do
            patch :validate
          end

          resource :sitemap, only: %i[show edit update] do
            patch :validate
          end

          resource :time_extensions, only: %i[show] do
            patch :validate
          end

          resources :validation_requests do
            get :post_validation_requests, on: :collection

            member do
              get :cancel_confirmation

              patch :cancel
            end
          end

          resources :additional_document_validation_requests, controller: :validation_requests
          resources :replacement_document_validation_requests, controller: :validation_requests
          resources :other_change_validation_requests, controller: :validation_requests
          resources :fee_change_validation_requests, controller: :validation_requests
          resources :red_line_boundary_change_validation_requests, controller: :validation_requests
          resources :description_change_validation_requests, controller: :validation_requests
          resources :ownership_certificate_validation_requests, controller: :validation_requests
          resources :time_extension_validation_requests, controller: :validation_requests

          resource :legislation, only: %i[show update]
        end

        namespace :review do
          root to: "base#index"

          resources :assessment_details, only: %i[update]

          resource :conditions, only: %i[update]

          resources :documents, only: %i[index] do
            patch :update, on: :collection
          end

          resources :consultation do
            resources :publicities do
              patch :update, on: :collection
              post :create, on: :collection
            end

            resource :neighbour_responses do
              patch :update, on: :collection
              post :create, on: :collection
            end
          end

          resource :heads_of_terms, only: %i[update]

          resources :immunity_details, only: %i[show update]

          resources :immunity_enforcements, only: :update

          resource :considerations, only: %i[edit update] do
            resources :items, only: %i[edit update], module: :considerations do
              concerns :positionable
            end
          end

          resource :informatives, only: %i[edit update] do
            resources :items, only: %i[edit update], module: :informatives do
              concerns :positionable
            end
          end

          resources :local_policies, only: %i[edit update show]

          resource :permitted_development_rights, only: %i[update]

          namespace :policy_areas do
            resources :policy_classes, only: %i[index show edit update]
          end

          resources :tasks, only: :index

          resource :cil_liability, only: %i[update], controller: :cil_liability

          resources :committee_decisions, only: %i[edit show update] do
            resources :notifications do
              get :edit, on: :collection
              get :show, on: :collection
              patch :update, on: :collection
            end
          end

          resources :recommendations, only: %i[new create update edit]

          resource :pre_commencement_conditions, only: %i[edit update show]
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
      resources :planning_applications, param: :reference, only: [] do
        member do
          get "decision_notice"
        end
      end
    end

    namespace :api do
      namespace :v1 do
        resources :planning_applications, only: %i[show] do
          member do
            get :decision_notice
          end
          resources :validation_requests, only: :index
          resources :description_change_validation_requests, only: %i[index update show]
          resources :replacement_document_validation_requests, only: %i[index update show]
          resources :additional_document_validation_requests, only: %i[index update show]
          resources :documents, only: %i[show]
          resources :other_change_validation_requests, only: %i[index update show]
          resources :fee_change_validation_requests, only: %i[index update show]
          resources :ownership_certificate_validation_requests, only: %i[index update show]
          resources :ownership_certificates, only: %i[create]
          resources :red_line_boundary_change_validation_requests, only: %i[index update show]
          resources :pre_commencement_condition_validation_requests, only: %i[index update show]
          resources :heads_of_terms_validation_requests, only: %i[index update show]
          resources :time_extension_validation_requests, only: %i[index update show]
          resources :neighbour_responses, only: :create
        end

        resources :local_authorities, only: %i[show], param: :subdomain

        resources :documents, only: :show do
          get :tags, on: :collection
        end
      end
    end
  end

  config_subdomain do
    mount BopsConfig::Engine, at: "/", as: :bops_config
  end

  mount BopsUploads::Engine, at: "/", as: :bops_uploads
end
