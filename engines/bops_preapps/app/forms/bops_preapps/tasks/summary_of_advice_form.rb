# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SummaryOfAdviceForm < Form
      self.task_actions = %w[save_and_complete save_draft]

      attribute :summary_tag
      attribute :entry

      after_initialize do
        @assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: :summary_of_advice)
      end

      attr_reader :assessment_detail

      private

      def update_assessment_detail
        if summary_tag.present? || entry.present?
          @assessment_detail.update!(summary_tag:, entry:)
        end
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
