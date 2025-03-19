# frozen_string_literal: true

BopsApi::Engine.routes.draw do
  get "/docs", to: redirect("v2/docs", status: 302)

  mount Rswag::Ui::Engine, at: "/docs"
  mount Rswag::Api::Engine, at: "/docs"

  defaults format: "json" do
    get "/v1/docs", to: redirect("docs/index.html?urls.primaryName=API%20V1%20Docs", status: 302)

    namespace :v2 do
      get "/ping", to: "ping#index"
      get "/docs", to: redirect("docs/index.html?urls.primaryName=API%20V2%20Docs", status: 302)

      resources :neighbour_responses, only: [:index]

      resources :planning_applications, only: [:index, :show, :create] do
        get :determined, on: :collection
        get :submission, on: :member
        get :search, on: :collection

        resource :documents, only: [:show]

        scope module: "planning_applications" do
          resources :validation_requests, only: [:index]
        end
      end

      resources :validation_requests, only: [:index]

      namespace :public do
        resources :planning_applications, only: [:show] do
          get :search, on: :collection
          resource :documents, only: [:show]
          get "comments/public", to: "comments_public#index"
        end
      end
    end
  end
end
