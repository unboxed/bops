# frozen_string_literal: true

BopsAdmin::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
  resource :profile, only: %i[show edit update]

  resources :consultees, except: %i[show]

  resource :setting, only: %i[show] do
    resource :determination_period, only: %i[edit update]
  end

  resources :informatives, except: %i[show]

  scope "/policy" do
    get "/", to: redirect("policy/areas"), as: "policy_root"

    with_options except: %i[show] do
      resources :policy_areas, path: "areas"
      resources :policy_guidances, path: "guidance"
      resources :policy_references, path: "references"
    end
  end

  resources :tokens, except: %i[show]

  resources :users, except: %i[show destroy] do
    get :resend_invite, on: :member
  end
end
