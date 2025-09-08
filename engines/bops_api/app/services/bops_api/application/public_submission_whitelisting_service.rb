# frozen_string_literal: true

module BopsApi
  module Application
    class PublicSubmissionWhitelistingService
      class WhitelistingError < StandardError; end

      def initialize(planning_application:)
        @planning_application = planning_application
      end

      def call
        return unless (submission = planning_application.params_v2.deep_symbolize_keys)

        filter_submission(FILTER, submission)
      rescue => e
        raise WhitelistingError, e.message
      end

      FILTER = {
        data: {
          application: {
            type: %i[value description]
          },
          applicant: {
            name: %i[first last]
          },
          property: {
            address: %i[singleline title street postcode town]
          },
          proposal: %i[description]
        },
        metadata: %i[id source]
      }

      private

      attr_reader :planning_application

      def filter_submission(filter, source, destination = nil)
        if destination.nil?
          destination = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
        end

        if filter.is_a?(Hash)
          filter.each do |key, subfilter|
            filter_submission(subfilter, source[key], destination[key]) if source.key?(key)
          end
        elsif filter.is_a?(Array)
          filter.each do |key|
            destination[key] = source[key] if source.key?(key)
          end
        else
          raise ArgumentError, "Unexpected filter type: #{filter.inspect}"
        end

        destination
      end
    end
  end
end
