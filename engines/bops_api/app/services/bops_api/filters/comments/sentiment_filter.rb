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
          sentiments = Array(params[:sentiment]).map(&:to_s)
          validate_sentiments!(sentiments)

          values = sentiments.map { |s| sentiment_mapping[s] }
          scope.where(summary_tag: values)
        end

        private

        attr_reader :model_class

        def validate_sentiments!(sentiments)
          invalid = sentiments - allowed_keys
          return if invalid.empty?

          raise ArgumentError,
            "Invalid sentiment(s): #{invalid.join(", ")}. Allowed values: #{allowed_keys.join(", ")}"
        end

        def allowed_keys
          @allowed_keys ||= sentiment_mapping.keys
        end

        def sentiment_mapping
          @sentiment_mapping ||= model_class.summary_tags.keys.each_with_object({}) do |key, hash|
            hash[key.to_s.camelize(:lower)] = key
          end
        end
      end
    end
  end
end
