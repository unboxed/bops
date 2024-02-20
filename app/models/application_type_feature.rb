# frozen_string_literal: true

class ApplicationTypeFeature
  include StoreModel::Model

  attribute :planning_conditions, :boolean, default: false
  attribute :permitted_development_rights, :boolean, default: true
end
