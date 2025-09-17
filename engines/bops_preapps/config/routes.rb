# frozen_string_literal: true

BopsPreapps::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
  resources :pre_applications, only: %(show), path: "/cases"

  scope "/cases/:reference" do
    resources :assign_users, only: %i[index] do
      patch :update, on: :collection
    end

    get "/*slug/edit", to: "tasks#edit", as: :edit_task
    patch "/*slug", to: "tasks#update"
    get "/*slug", to: "tasks#show", as: :task
  end
end
