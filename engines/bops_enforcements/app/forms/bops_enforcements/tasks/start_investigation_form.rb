# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class StartInvestigationForm < BaseForm
      attr_reader :enforcement

      validate :case_record_assigned_user
      validate :complainant_email

      def initialize(task)
        super

        @enforcement = case_record.caseable
      end

      def permitted_fields(params)
      end

      def update(params)
        return false unless valid?

        ActiveRecord::Base.transaction do
          enforcement.start_investigation!
          task.update!(status: "completed")
          task.parent.update!(status: "completed")
          SendStartInvestigationEmailJob.perform_later(enforcement)
        end
      end

      def redirect_url
        enforcement_path(case_record)
      end

      def case_record_assigned_user
        errors.add(:base, "Assign a case officer before starting the investigation.") unless case_record.user
      end

      def complainant_email
        errors.add(:base, "Complainant email is required") unless enforcement.complainant&.email
      end
    end
  end
end
