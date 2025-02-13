# frozen_string_literal: true

require "sidekiq/web"

BopsConfig::Engine.routes.draw do
  root to: redirect("dashboard")

  authenticate :user, ->(u) { u.global_administrator? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  resource :dashboard, only: %i[show]

  resources :application_types do
    scope module: "application_types" do
      with_options only: %i[edit update] do
        resource :category, controller: "category"
        resource :decisions
        resource :determination_period
        resource :document_tags
        resource :features
        resource :legislation
        resource :reporting, controller: "reporting"
        resource :status
      end
    end
  end

  with_options except: %i[show] do
    resources :legislation
    resources :decisions
    resources :reporting_types

    namespace :gpdo do
      resources :policy_schedules, param: :number, path: "schedule" do
        resources :policy_parts, param: :number, path: "part" do
          resources :policy_class, param: :section, path: "class" do
            resources :policy_sections, param: :section, path: "section", constraints: {section: /.*/}
          end
        end
      end
    end
  end

  resources :users, except: %i[show] do
    get :resend_invite, on: :member
    patch :reactivate, on: :member
  end

  resources :local_authorities, except: %i[destroy]
end
