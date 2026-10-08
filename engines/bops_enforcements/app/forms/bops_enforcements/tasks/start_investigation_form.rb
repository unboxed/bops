# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class StartInvestigationForm < Form
      self.task_actions = %w[start_investigation]

      validate :complainant_email

      def start_investigation
        enforcement.start_investigation!
        task.update!(status: "completed")
        task.parent.update!(status: "completed")
        SendStartInvestigationEmailJob.perform_later(enforcement)
      end

      def redirect_url
        enforcement_path(enforcement)
      end

      def complainant_email
        errors.add(:base, "Complainant email is required") unless enforcement.complainant&.email
      end
    end
  end
end
