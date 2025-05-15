# frozen_string_literal: true

BopsSubmissions::Engine.routes.draw do
  namespace :v2 do
    resources :submissions, only: %i[create]
  end

  mount Rswag::Ui::Engine => "/docs"
  mount Rswag::Api::Engine => "/docs"
end
