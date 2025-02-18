# frozen_string_literal: true

BopsAdmin::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
  resource :profile, only: %i[show edit update]

  resources :consultees, except: %i[show]

  resource :setting, only: %i[show] do
    resource :determination_period, only: %i[edit update]
  end

  with_options except: %i[show] do
    resources :informatives
    resources :requirements
  end

  scope "/policy" do
    get "/", to: redirect("policy/areas"), as: "policies"

    with_options except: %i[show] do
      resources :policy_areas, path: "areas"
      resources :policy_guidances, path: "guidance"
      resources :policy_references, path: "references"
    end
  end

  resources :tokens, except: %i[show]

  resources :users, except: %i[show] do
    get :resend_invite, on: :member
    patch :reactivate, on: :member
  end
end
