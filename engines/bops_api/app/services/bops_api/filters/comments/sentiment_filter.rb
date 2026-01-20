# frozen_string_literal: true

module BopsApi
  module Filters
    module Comments
      class SentimentFilter < BaseFilter
        def initialize(model_class)
          @model_class = model_class
        end

        def applicable?(params)
          params[:sentiment].present?
        end

        def apply(scope, params)
          sentiments = Array(params[:sentiment]).map { |s| s.to_s.underscore }
          validate_sentiments!(sentiments)

          scope.where(summary_tag: sentiments)
        end

        private

        attr_reader :model_class

        def validate_sentiments!(sentiments)
          invalid = sentiments - allowed_values
          return if invalid.empty?

          raise ArgumentError,
            "Invalid sentiment(s): #{invalid.join(", ")}. Allowed values: #{allowed_values.join(", ")}"
        end

        def allowed_values
          @allowed_values ||= model_class.summary_tags.keys.map(&:to_s)
        end
      end
    end
  end
end
