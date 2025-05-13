# frozen_string_literal: true

BopsSubmissions::Engine.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :submissions, only: %i[create]
    end
  end

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
end
