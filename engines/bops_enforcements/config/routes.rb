# frozen_string_literal: true

BopsEnforcements::Engine.routes.draw do
  root to: redirect("enforcements")

  resources :enforcements, only: %i[index show]

  scope "/cases/:case_id" do
    get "/*slug/edit", to: "tasks#edit", as: :edit_task
    patch "/*slug", to: "tasks#update"
    get "/*slug", to: "tasks#show", as: :task
  end
end
