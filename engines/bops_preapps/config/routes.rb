# frozen_string_literal: true

BopsPreapps::Engine.routes.draw do
  root to: "pre_applications#index"

  resources :pre_applications, only: %i[index show] do
    collection do
      get :mine, to: "tabs#mine"
      get :unassigned, to: "tabs#unassigned"
      get :closed, to: "tabs#closed"
      get :all, to: "tabs#all_cases"
    end
  end
  get "/planning_applications", to: "pre_applications#index"

  scope "/:reference" do
    get "/", to: redirect("/planning_applications/%{reference}")

    get "/cancel", to: "cancel_requests#show", as: :cancel_request
    patch "/cancel", to: "cancel_requests#update"

    resources :consultees, only: %i[new create], param: :constraint_id
    resources :consultees, only: [] do
      resources :responses, only: %i[index new create], controller: "consultee_responses"
    end
    resources :constraint_consultees, only: %i[destroy]
    resource :assign_constraint, only: %i[create]

    get "/*slug/edit", to: "tasks#edit", as: :edit_task
    post "/*slug", to: "tasks#update"
    patch "/*slug", to: "tasks#update"
    get "/*slug", to: "tasks#show", as: :task
  end
end
