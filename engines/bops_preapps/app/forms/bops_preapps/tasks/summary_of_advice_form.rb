# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SummaryOfAdviceForm < Form
      self.task_actions = %w[save_and_complete save_draft]

      attribute :summary_tag
      attribute :entry

      def update(params)
        assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: :summary_of_advice)

        super do
          transaction do
            assessment_detail.update!(summary_tag:, entry:) if summary_tag.present? || entry.present?

            if action.in?(task_actions)
              send(action.to_sym)
            else
              raise ArgumentError, "Invalid task action: #{action.inspect}"
            end
          end
        end
      end
    end
  end
end
