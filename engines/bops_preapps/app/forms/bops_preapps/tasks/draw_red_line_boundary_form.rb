# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class DrawRedLineBoundaryForm < Form
      self.task_actions = %w[save_and_complete]

      attribute :boundary_geojson, :string

      validates :boundary_geojson, presence: {message: I18n.t("bops_preapps.tasks.update.draw-red-line-boundary.failure")}

      def boundary_geojson=(value)
        return if value.blank? || value == "null"
        super
      end

      def update(params)
        super do
          if action.in?(task_actions)
            send(action.to_sym)
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
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
        return if boundary_geojson.blank?

        audit_action = planning_application.boundary_geojson.blank? ? "created" : "updated"

        planning_application.update!(boundary_geojson:, boundary_created_by: Current.user, valid_red_line_boundary: true)
        planning_application.audit_boundary_geojson!(audit_action)
      end
    end
  end
end
