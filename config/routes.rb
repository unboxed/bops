# frozen_string_literal: true

Rails.application.routes.draw do
  extend BopsCore::Routing

  get :healthcheck, to: proc { [200, {}, %w[OK]] }

  applicants_domain do
    draw :applicants
  end

  bops_domain do
    draw :bops
  end
end
