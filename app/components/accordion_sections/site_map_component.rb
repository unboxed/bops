# frozen_string_literal: true

module AccordionSections
  class SiteMapComponent < AccordionSections::BaseComponent
    private

    def site_map_drawn_by
      planning_application.boundary_created_by&.name || t(".applicant")
    end

    def change_request_link_path
      case change_request&.state
      when "open", "closed"
        planning_application_validation_red_line_boundary_change_validation_request_path(
          planning_application,
          change_request
        )
      else
        new_planning_application_validation_red_line_boundary_change_validation_request_path(
          planning_application
        )
      end
    end

    def change_request_link_text
      case change_request&.state
      when "open"
        t(".view_requested_red")
      when "closed"
        t(".view_applicants_response")
      else
        t(".request_approval_for")
      end
    end

    def change_request
      @change_request ||= planning_application
        .red_line_boundary_change_validation_requests
        .post_validation
        .last
    end
  end
end
