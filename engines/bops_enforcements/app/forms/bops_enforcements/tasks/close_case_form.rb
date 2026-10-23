# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CloseCaseForm < Form
      attribute :reason, :string
      attribute :other_reason, :string
      attribute :detail, :string

      validates :other_reason, presence: true, if: -> { reason == "other" }

      def redirect_url
        enforcement_path(enforcement)
      end

      private

      def save_and_complete
        super do
          closed_reason = (reason == "other") ? other_reason : I18n.t(reason, scope: "bops_enforcements.tasks.close-case.show.reason")
          enforcement.update!(closed_reason:, closed_detail: params[:detail])
          enforcement.close!
          SendCloseInvestigationEmailJob.perform_later(enforcement,
            closed_reason: reason,
            other_reason: other_reason,
            additional_comment: detail)
        end
      end
    end
  end
end
