# frozen_string_literal: true

module TaskListItems
  class CheckRedLineBoundaryComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(
      :red_line_boundary_change_validation_requests,
      to: :planning_application
    )

    def link_text
      t(".check_red_line")
    end

    def link_path
      if render_sitemap_path?
        planning_application_sitemap_path(planning_application)
      else
        planning_application_red_line_boundary_change_validation_request_path(
          planning_application,
          change_request
        )
      end
    end

    def link_active?
      planning_application.boundary_geojson.present?
    end

    def status
      @status = if valid?
                  :valid
                elsif red_line_boundary_change_validation_requests.open_or_pending.any?
                  :invalid
                elsif change_request&.approved == false
                  :updated
                else
                  :not_started
                end
    end

    def render_sitemap_path?
      status == :not_started ||
        (status == :valid && red_line_boundary_change_validation_requests.closed.none?)
    end

    def valid?
      planning_application.valid_red_line_boundary? || change_request&.approved?
    end

    def change_request
      @change_request ||= red_line_boundary_change_validation_requests
                          .not_cancelled
                          .order(:created_at)
                          .last
    end
  end
end
