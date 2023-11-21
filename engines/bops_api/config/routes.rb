# frozen_string_literal: true

BopsApi::Engine.routes.draw do
  defaults format: "json" do
    namespace :v2 do
      get "/ping", to: "ping#index"
    end
  end
end
