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

      resources :planning_applications, only: [:index, :show, :create] do
        get :determined, on: :collection
      end

      namespace :public do
        resources :planning_applications, only: [] do
          get :search, on: :collection
        end
      end
    end
  end
end
