# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class StartInvestigationForm < BaseForm
      attr_reader :enforcement

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

      def complainant_email
        errors.add(:base, "Complainant email is required") unless enforcement.complainant&.email
      end
    end
  end
end
