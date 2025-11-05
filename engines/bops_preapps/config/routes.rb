# frozen_string_literal: true

BopsPreapps::Engine.routes.draw do
  root to: "pre_applications#index"

  resources :pre_applications, only: %i[index show]
  get "/planning_applications", to: "pre_applications#index"

  scope "/:reference" do
    get "/*slug/edit", to: "tasks#edit", as: :edit_task
    patch "/*slug", to: "tasks#update"
    get "/*slug", to: "tasks#show", as: :task
  end
end
