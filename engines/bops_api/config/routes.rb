# frozen_string_literal: true

BopsApi::Engine.routes.draw do
  mount Rswag::Ui::Engine, at: "/docs"
  mount Rswag::Api::Engine, at: "/docs"

  defaults format: "json" do
    namespace :v2 do
      get "/ping", to: "ping#index"

      resources :planning_applications, only: [:index, :show, :create] do
        get :determined, on: :collection
      end
    end
  end
end
