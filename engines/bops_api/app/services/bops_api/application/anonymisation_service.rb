# frozen_string_literal: true

module BopsApi
  module Application
    class AnonymisationService
      class AnonymiseError < StandardError; end

      ANONYMISATION_TEXT = "XXXXX"

      def initialize(planning_application:)
        @planning_application = planning_application
      end

      def call!
        unless planning_application.from_production?
          raise AnonymiseError, "Anonymizing is only permitted for production cases."
        end

        anonymize_personal_information.tap(&:save!)
      rescue ActiveRecord::ActiveRecordError => e
        raise AnonymiseError, e.message
      end

      private

      attr_reader :planning_application

      def anonymize_personal_information
        planning_application.tap do |record|
          record.applicant_first_name = ANONYMISATION_TEXT
          record.applicant_last_name = ANONYMISATION_TEXT
          record.applicant_phone = ANONYMISATION_TEXT
          record.applicant_email = "applicant@example.com"
          record.applicant_address_1 = ANONYMISATION_TEXT
          record.applicant_address_2 = ANONYMISATION_TEXT
          record.applicant_town = ANONYMISATION_TEXT
          record.applicant_county = ANONYMISATION_TEXT
          record.applicant_postcode = ANONYMISATION_TEXT
          record.agent_first_name = ANONYMISATION_TEXT
          record.agent_last_name = ANONYMISATION_TEXT
          record.agent_phone = ANONYMISATION_TEXT
          record.agent_email = "agent@example.com"
          record.agent_address_1 = ANONYMISATION_TEXT
          record.agent_address_2 = ANONYMISATION_TEXT
          record.agent_town = ANONYMISATION_TEXT
          record.agent_county = ANONYMISATION_TEXT
          record.agent_postcode = ANONYMISATION_TEXT
        end
      end
    end
  end
end
