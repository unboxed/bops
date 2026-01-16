# frozen_string_literal: true

module BopsApi
  module Filters
    class DateRangeFilter < BaseFilter
      def initialize(field_name)
        @field_name = field_name
        @from_key = :"#{field_name}From"
        @to_key = :"#{field_name}To"
        @scope_method = "#{field_name.to_s.underscore}_between"
      end

      def applicable?(params)
        params[@from_key].present? || params[@to_key].present?
      end

      def apply(scope, params)
        scope.public_send(@scope_method, from_time(params), to_time(params))
      end

      private

      def from_time(params)
        parse_date(params[@from_key])&.beginning_of_day || Time.zone.at(0)
      end

      def to_time(params)
        parse_date(params[@to_key])&.end_of_day || Time.zone.now.end_of_day
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
