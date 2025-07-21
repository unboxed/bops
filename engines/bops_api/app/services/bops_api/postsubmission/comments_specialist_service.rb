# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class CommentsSpecialistService < CommentsBaseService
      private

      # Defines allowed fields and their default sort orders
      def allowed_sort_fields
        {
          "receivedAt" => {column: "received_at", default_order: "desc"},
          "id" => {column: "consultee_responses.id", default_order: "asc"}
        }
      end

      # Defines allowed sentiment values and their corresponding database values
      def allowed_sentiment_values
        Consultee::Response.summary_tags.keys.map do |s|
          {s.to_s.camelize(:lower) => {value: s}}
        end
      end
    end
  end
end
