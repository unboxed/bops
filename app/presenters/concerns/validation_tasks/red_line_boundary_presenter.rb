# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class RedLineBoundaryPresenter < PlanningApplicationPresenter
    attr_reader :red_line_boundary

    def initialize(template, planning_application)
      super(template, planning_application)

      @red_line_boundary = planning_application.red_line_boundary_change_validation_requests.not_cancelled.last
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat validate_link
      end

      html.concat validation_item_tag
    end

    private

    def validate_link
      case validation_item_status
      when "Valid"
        valid_link
      when "Not checked yet"
        link_to_if(planning_application.boundary_geojson.present?, "Validate red line boundary",
                   planning_application_sitemap_path(planning_application), class: "govuk-link")
      when "Invalid", "Updated"
        link_to_if(planning_application.boundary_geojson.present?, "Validate red line boundary",
                   planning_application_red_line_boundary_change_validation_request_path(
                     planning_application, red_line_boundary
                   ), class: "govuk-link")
      else
        raise ArgumentError, "Status: #{validation_item_status} is not a valid option"
      end
    end

    def validation_item_status
      status = if invalid_planning_application?
                 "Invalid"
               elsif valid_planning_application?
                 "Valid"
               elsif red_line_boundary&.approved == false
                 "Updated"
               else
                 "Not checked yet"
               end

      raise "Status: #{status} is not included in the permitted list" unless STATUSES.include?(status)

      status
    end

    def valid_planning_application?
      planning_application.valid_red_line_boundary || red_line_boundary&.approved?
    end

    def invalid_planning_application?
      planning_application.red_line_boundary_change_validation_requests.open_or_pending.any?
    end

    def updated_planning_application?
      red_line_boundary&.approved == false
    end

    def valid_link
      if planning_application.red_line_boundary_change_validation_requests.closed.any?
        link_to_if(planning_application.boundary_geojson.present?, "Validate red line boundary",
                   planning_application_red_line_boundary_change_validation_request_path(
                     planning_application, red_line_boundary
                   ), class: "govuk-link")
      else
        link_to_if(planning_application.boundary_geojson.present?, "Validate red line boundary",
                   planning_application_sitemap_path(planning_application), class: "govuk-link")
      end
    end
  end
end
