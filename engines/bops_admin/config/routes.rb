# frozen_string_literal: true

BopsAdmin::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
  resource :profile, only: %i[show edit update]
  resource :accessibility, only: %i[edit update], controller: "accessibility"
  resource :site_notices, only: %i[edit update]

  resource :notify, only: %i[show edit update], controller: "notify" do
    resource :email, :sms, :letter, only: %i[new create], module: "notify"
  end

  resources :consultees, except: %i[show]

  resources :application_types, only: %i[index show] do
    scope module: "application_types" do
      with_options only: %i[edit update] do
        resource :determination_period
        resource :disclaimer
        resource :requirements
      end
    end
  end

  with_options except: %i[show] do
    resources :informatives
    resources :requirements
    resources :constraints
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

  resources :submissions, only: %i[index show]
end
