# frozen_string_literal: true

module BopsEnforcements
  class SearchForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :urgent, :boolean
    attribute :status, :list, default: []
  end
end
