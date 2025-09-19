# frozen_string_literal: true

module BopsApi
  module Application
    class PublicSubmissionWhitelistingService
      class WhitelistingError < StandardError; end

      def initialize(planning_application:)
        @planning_application = planning_application
        @submission = planning_application.params_v2
      end

      def call
        return unless submission

        result = filter_submission(FILTER, submission)

        result[:files] = whitelisted_files if submission["files"]
        result
      rescue => e
        raise WhitelistingError, e.message
      end

      FILTER = {
        data: {
          application: %i[type declaration planningApp leadDeveloper vacantBuildingCredit],
          applicant: %i[name type address agent],
          property: %i[
            address boundary flood planning localAuthorityDistrict
            region trees type units ward occupation ownership parking
            socialLandlord titleNumber EPC
          ],
          proposal: %i[
            access boundary charging cost date description
            ecology energy extend flood greenRoof new newBuildings newDwellings
            newStoreys parking projectType structures units urbanGreeningFactor
            utilities waste water
          ],
          user: %i[role]
        }
      }

      private

      attr_reader :planning_application, :submission

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

      def submission_file_names
        submission["files"].map do |file|
          URI.decode_uri_component(File.basename(URI.parse(file["name"]).path))
        end
      end

      def whitelisted_files
        planning_application.documents.map do |document|
          filename = document.file.filename.to_s
          if document.publishable? && submission_file_names.include?(filename)
            {
              name: filename,
              type: document.tags.map { |tag| {"value" => tag, "description" => tag.humanize} }
            }
          else
            {
              name: "Unpublished document - sensitive"
            }
          end
        end
      end
    end
  end
end
