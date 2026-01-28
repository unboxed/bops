# frozen_string_literal: true

module BopsApi
  module Filters
    class ApplicationStatusFilter < BopsCore::Filters::StatusFilter
      def initialize
        super(param_key: :applicationStatus)
      end

      private

      def normalized_values(params)
        Array(params[param_key])
          .flat_map { |status| status.to_s.split(",") }
          .compact_blank
          .uniq
      end
    end
  end
end
