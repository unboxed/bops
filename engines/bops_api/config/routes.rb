# frozen_string_literal: true

BopsApi::Engine.routes.draw do
  mount Rswag::Ui::Engine, at: "/docs"
  mount Rswag::Api::Engine, at: "/docs"

  defaults format: "json" do
    namespace :v2 do
      get "/ping", to: "ping#index"
    end
  end
end
