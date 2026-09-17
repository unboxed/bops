# frozen_string_literal: true

BopsEnforcements::Engine.routes.draw do
  root to: redirect("enforcements")

  resources :enforcements, only: %i[index show] do
    with_options on: :collection do
      get :unassigned
      get :closed
      get :updated
      get :all
    end
  end

  scope "/cases/:case_id" do
    resources :assign_users, only: %i[index] do
      patch :update, on: :collection
    end

    get "/check-breach-report", to: redirect(Bops::InitialTaskRedirector.new("Check"))
    get "/investigate-and-decide", to: redirect(Bops::InitialTaskRedirector.new("Investigate"))
    get "/review-recommendation", to: redirect(Bops::InitialTaskRedirector.new("Review"))
    get "/serve-and-monitor", to: redirect(Bops::InitialTaskRedirector.new("Serve and monitor"))
    # get "/process-an-appeal", to: redirect(Bops::InitialTaskRedirector.new('Appeal'))

    get "/*slug/edit", to: "tasks#edit", as: :edit_task
    patch "/*slug", to: "tasks#update"
    get "/*slug", to: "tasks#show", as: :task
  end
end
