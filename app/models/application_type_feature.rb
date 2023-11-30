# frozen_string_literal: true

class ApplicationTypeFeature
  include StoreModel::Model

  attribute :permitted_development_rights, :boolean, default: true
end
