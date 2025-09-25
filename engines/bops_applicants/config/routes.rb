# frozen_string_literal: true

BopsApplicants::Engine.routes.draw do
  extend BopsCore::Routing

  local_authority_subdomain do
    defaults format: "json" do
      get "/addresses", to: "addresses#index"
    end

    controller "pages" do
      get "/", action: "index", as: "root"
      get "/accessibility", action: "accessibility"
    end

    get "/blobs/:key", to: "blobs#show", as: "blob"
    get "/files/:key", to: "files#show", as: "file"

    resources :planning_applications, param: :reference, only: %i[show] do
      resource :site_notice, only: %i[show]

      resources :neighbour_responses, only: %i[new create] do
        collection do
          get :start
          get :thank_you
        end
      end
    end

    resources :validation_requests, only: %i[index] do
      resource :ownership_certificate, only: %i[new create]
    end

    with_options only: %i[show edit update] do
      resources :description_change_validation_requests
      resources :replacement_document_validation_requests
      resources :additional_document_validation_requests
      resources :other_change_validation_requests
      resources :fee_change_validation_requests
      resources :red_line_boundary_change_validation_requests
      resources :ownership_certificate_validation_requests
      resources :pre_commencement_condition_validation_requests
      resources :heads_of_terms_validation_requests
      resources :time_extension_validation_requests
    end
  end
end
