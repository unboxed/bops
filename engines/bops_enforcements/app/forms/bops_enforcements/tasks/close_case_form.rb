# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CloseCaseForm < Form
      self.task_actions = %w[close_case sign_off_closure]

      REASONS = %w[not_enforcement_issue permission_not_required not_expedient permission_previously_granted duplicate anonymous].freeze

      attribute :reason, :string
      attribute :other_reason, :string
      attribute :detail, :string
      attribute :manager_approval, :boolean
      attribute :closure_confirmation, :boolean
      attribute :closure_rejection_reason, :string

      with_options on: :close_case do
        validates :reason, presence: {message: "Select an option"}
        validates :other_reason, presence: true, if: -> { reason == "other" }
        validates :manager_approval, inclusion: {in: [true, false], message: "Select an option"}
        validates :manager_approval, acceptance: {message: I18n.t("bops_enforcements.tasks.close-case.show.manager_approval.required_error")}, if: -> { reason == "not_expedient" }
      end

      with_options on: :sign_off_closure do
        validates :closure_confirmation, inclusion: {in: [true, false], message: "Select an option"}
        validates :closure_rejection_reason, presence: true, if: -> { !closure_confirmation }
      end

      after_initialize do
        if !enforcement.requested_closure? && !Current.user.reviewer? && enforcement.closure_rejection_reason.present?
          # this is not really an ideal way of clearing the notification
          enforcement.update(closure_rejection_reason: "")
        end
      end

      def reasons
        REASONS
      end

      def flash(type, controller)
        if action == "close_case" && invalid?(:close_case)
          return "Manager approval is required. Submit the case closure recommendation to a senior officer or a manager"
        end

        result = case type
        when :notice
          "success"
        when :alert
          "failure"
        end

        activity = if action == "sign_off_closure" && !closure_confirmation
          "reopened"
        else
          "closed"
        end

        I18n.t("bops_enforcements.tasks.close-case.#{result}", action: activity)
      end

      def redirect_url
        enforcement_path(enforcement)
      end

      private

      def close_case
        closed_reason = (reason == "other") ? other_reason : I18n.t(reason, scope: "bops_enforcements.tasks.close-case.show.reason")
        enforcement.update!(closed_reason:, closed_detail: detail, closure_rejection_reason: nil)

        if manager_approval
          enforcement.request_closure!
        else
          task.complete!
          enforcement.close!
          send_close_case_email!
        end
      end

      def sign_off_closure
        if closure_confirmation
          task.complete!
          enforcement.close!
          send_close_case_email!
        else
          enforcement.update!(closed_reason: "",
            closed_detail: "",
            closure_rejection_reason:)

          enforcement.reject_closure!
        end
      end

      def send_close_case_email!
        # We only store the value here, not the key. And if the key is other, we only store user input.
        # Need to refactor this to track it better now that the sending may be decoupled from the submission of the form.
        reason_codes = I18n.t("bops_enforcements.tasks.close-case.show.reason")
        closed_reason = reason_codes.invert[enforcement.closed_reason] || "other"

        other_reason = if closed_reason == "other"
          enforcement.closed_reason
        end

        SendCloseInvestigationEmailJob.perform_later(enforcement,
          closed_reason:,
          other_reason:,
          additional_comment: enforcement.closed_detail)
      end
    end
  end
end
