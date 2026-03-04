# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SummaryOfAdviceForm < Form
      self.task_actions = %w[save_and_complete save_draft]

      attribute :summary_tag
      attribute :entry

      private

      def update_assessment_detail
        assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: :summary_of_advice)
        assessment_detail.update!(summary_tag:, entry:) if summary_tag.present? || entry.present?
      end

      def save_and_complete
        super do
          update_assessment_detail
        end
      end

      def save_draft
        super do
          update_assessment_detail
        end
      end
    end
  end
end
