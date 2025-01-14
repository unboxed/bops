# frozen_string_literal: true

BopsConsultees::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
end
