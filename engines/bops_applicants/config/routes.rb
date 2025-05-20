# frozen_string_literal: true

BopsApplicants::Engine.routes.draw do
  extend BopsCore::Routing

  local_authority_subdomain do
    controller "pages" do
      get "/", action: "index", as: "root"
      get "/accessibility", action: "accessibility"
    end

    resources :planning_applications, param: :reference, only: %i[show] do
      resource :site_notice, only: %i[show]
    end
  end
end
