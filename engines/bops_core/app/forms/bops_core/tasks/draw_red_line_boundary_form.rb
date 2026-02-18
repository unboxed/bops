# frozen_string_literal: true

module BopsCore
  module Tasks
    module DrawRedLineBoundaryForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_and_complete edit_form]

        attribute :boundary_geojson, :geojson

        validates :boundary_geojson, presence: {message: "Draw a red line boundary"}
      end

      def sitemap_documents
        @sitemap_documents ||= planning_application.documents.with_siteplan_tags
      end

      private

      def save_and_complete
        transaction do
          persist_boundary!
          task.complete!
        end
      end

      def persist_boundary!
        audit_action = planning_application.boundary_geojson.blank? ? "created" : "updated"

        planning_application.update!(boundary_geojson:, boundary_created_by: Current.user, valid_red_line_boundary: true)
        planning_application.audit_boundary_geojson!(audit_action)
      end
    end
  end
end
