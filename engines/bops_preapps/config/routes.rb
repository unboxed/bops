# frozen_string_literal: true

BopsPreapps::Engine.routes.draw do
  root to: redirect("dashboard")

  resource :dashboard, only: %i[show]
end
