# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckApplicationDetailsForm < Form
      self.task_actions = %w[save_and_complete]

      attribute :description_matches_documents
      attribute :documents_consistent
      attribute :proposal_details_match_documents
      attribute :proposal_details_match_documents_comment
      attribute :site_map_correct
      attribute :site_map_correct_comment

      def initialize(task, params = {})
        super

        @consistency_checklist = planning_application.consistency_checklist ||
          planning_application.create_consistency_checklist

        attributes.each do |attr, _val|
          send("#{attr}=", consistency_checklist.send(attr))
        end
      end
      attr_reader :consistency_checklist

      private

      def save_and_complete
        consistency_checklist.update!(attributes)
        task.complete!
      end
    end
  end
end
