# frozen_string_literal: true

module BopsApi
  module Filters
    class DateRangeFilter < BaseFilter
      class << self
        def for(field_name)
          ->(scope, params) { call(scope, params, field_name) }
        end

        def call(scope, params, field_name)
          return scope unless applicable?(params, field_name)

          apply(scope, params, field_name)
        end

        private

        def applicable?(params, field_name)
          params[from_key(field_name)].present? || params[to_key(field_name)].present?
        end

        def apply(scope, params, field_name)
          scope.public_send(scope_method(field_name), from_time(params, field_name), to_time(params, field_name))
        end

        def from_key(field_name)
          :"#{field_name}From"
        end

        def to_key(field_name)
          :"#{field_name}To"
        end

        def scope_method(field_name)
          "#{field_name.to_s.underscore}_between"
        end

        def from_time(params, field_name)
          parse_date(params[from_key(field_name)])&.beginning_of_day || Time.zone.at(0)
        end

        def to_time(params, field_name)
          parse_date(params[to_key(field_name)])&.end_of_day || Time.zone.now.end_of_day
        end

        def parse_date(date_string)
          return if date_string.blank?

          Date.iso8601(date_string)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
