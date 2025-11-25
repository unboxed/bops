# frozen_string_literal: true

BopsSubmissions::Engine.routes.draw do
  mount Rswag::Ui::Engine => "/docs"
  mount Rswag::Api::Engine => "/docs"

  defaults format: "json" do
    namespace :v2 do
      get "/ping", to: "ping#index"

      post "/submissions(/:sqid)", to: "submissions#create", as: :submissions
    end
  end
end
