# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CheckSiteLocationForm < Form
      include BopsCore::Tasks::CheckRedLineBoundaryForm

      self.task_actions = %w[save_and_complete mark_as_valid delete_request edit_form]

      attribute :boundary_geojson
      attribute :valid_red_line_boundary, :boolean

      after_initialize do
        self.boundary_geojson ||= enforcement.boundary_geojson
      end

      def enforcement
        case_record.caseable
      end

      def validation_request
        false
      end

      def redirect_url
        case action
        when "save_and_complete"
          if valid_red_line_boundary
            task.url
          else
            task.edit_url
          end
        else
          super
        end
      end

      def save_and_complete
        # enforcement.update!(valid_red_line_boundary:)
        # valid_red_line_boundary ? task.complete! :
        task.in_progress!
      end

      def edit_form
        enforcement.update!(boundary_geojson:)
      end
    end
  end
end
