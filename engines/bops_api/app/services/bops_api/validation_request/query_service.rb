# frozen_string_literal: true

module BopsApi
  module ValidationRequest
    class QueryService
      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      attr_reader :scope, :params

      def call
        Pagination.new(scope: filter_by_params, params:).paginate
      end

      private

      def filter_by_params
        scope
          .then { |s| filter_by_type(s) }
          .then { |s| filter_from_date(s) }
          .then { |s| filter_to_date(s) }
          .then { |s| s.reorder(:notified_at) }
      rescue Date::Error
        scope.none
      end

      def filter_by_type(scoping)
        param?(:type) ? scoping.where(type: param(:type)) : scoping
      end

      def filter_from_date(scoping)
        param?(:from_date) ? scoping.where(notified_at: param(:from_date, :date)...) : scoping
      end

      def filter_to_date(scoping)
        param?(:to_date) ? scoping.where(notified_at: ...param(:to_date, :date).tomorrow) : scoping
      end

      def param?(name)
        params[name].present?
      end

      def param(name, type = :string)
        case type
        when :date
          Date.iso8601(params[name].to_s)
        else
          params[name].to_s
        end
      end
    end
  end
end
