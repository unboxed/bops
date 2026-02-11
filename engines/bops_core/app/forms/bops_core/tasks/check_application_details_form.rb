# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckApplicationDetailsForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_and_complete save_draft]

        attribute :description_matches_documents
        attribute :documents_consistent
        attribute :proposal_details_match_documents
        attribute :proposal_details_match_documents_comment
        attribute :site_map_correct
        attribute :site_map_correct_comment
      end

      attr_reader :consistency_checklist

      def initialize(task, params = {})
        super

        @consistency_checklist = planning_application.consistency_checklist ||
          planning_application.create_consistency_checklist

        attributes.each do |attr, _val|
          send("#{attr}=", consistency_checklist.send(attr))
        end
      end

      def update(params)
        super do
          transaction do
            consistency_checklist.update!(attributes)

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
