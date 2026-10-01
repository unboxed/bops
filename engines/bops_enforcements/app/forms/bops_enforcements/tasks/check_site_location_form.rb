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

      validates :boundary_geojson, presence: true, on: :edit_form

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

      def flash(type, controller)
        result = case type
        when :notice
          "success.#{action}"
        when :alert
          "failure.#{action}"
        end

        if action == "save_and_complete" && type == :notice
          result << ".#{valid_red_line_boundary}"
        end

        I18n.t("bops_enforcements.tasks.update.check-site-location.#{result}")
      end

      private

      def save_and_complete
        enforcement.update!(valid_red_line_boundary:)
        if valid_red_line_boundary
          task.complete!
          task.parent.complete!
        else
          task.in_progress!
          task.parent.in_progress!
        end
      end

      def edit_form
        enforcement.update!(boundary_geojson:, valid_red_line_boundary: true)
      end
    end
  end
end
