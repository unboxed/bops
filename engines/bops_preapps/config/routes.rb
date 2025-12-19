# frozen_string_literal: true

BopsPreapps::Engine.routes.draw do
  root to: "pre_applications#index"

  resources :pre_applications, only: %i[index show]
  get "/planning_applications", to: "pre_applications#index"

  scope "/:reference" do
    get "/", to: redirect("/planning_applications/%{reference}")

    resources :validation_requests, path: "/validation/requests", except: %i[index] do
      resource :cancellation, only: %i[new create], module: "validation_requests"
    end

    get "/cancel", to: "cancel_requests#show", as: :cancel_request
    patch "/cancel", to: "cancel_requests#update"
    get "/*slug/edit", to: "tasks#edit", as: :edit_task
    post "/*slug", to: "tasks#update"
    patch "/*slug", to: "tasks#update"
    get "/*slug", to: "tasks#show", as: :task
  end
end
