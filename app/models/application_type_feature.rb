# frozen_string_literal: true

class ApplicationTypeFeature
  include StoreModel::Model

  attribute :planning_conditions, :boolean, default: false
  attribute :permitted_development_rights, :boolean, default: true
  attribute :site_visits, :boolean, default: false
  attribute :include_bank_holidays, :boolean, default: true
end
