# frozen_string_literal: true

module BopsApi
  module Filters
    class FieldFilter < BaseFilter
      ALLOWED_COLUMNS = %w[reference description postcode].freeze

      class << self
        def for(field_name, column_name: nil)
          col = column_name || field_name.to_s
          ->(scope, params) { call(scope, params, field_name, col) }
        end

        def call(scope, params, field_name, column_name = nil)
          col = column_name || field_name.to_s
          return scope if params[field_name].blank?
          return scope unless ALLOWED_COLUMNS.include?(col)

          scope.where("LOWER(#{col}) LIKE ?", "%#{params[field_name].downcase}%")
        end
      end
    end
  end
end
