# frozen_string_literal: true

class SiteMapComponent < ViewComponent::Base
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  private

  attr_reader :planning_application

  private

  def site_map_drawn_by
    planning_application.boundary_created_by&.name || t(".applicant")
  end

  def change_request_link_path
    case change_request&.state
    when "open", "closed"
      planning_application_validation_validation_request_path(
        planning_application,
        change_request
      )
    else
      new_planning_application_validation_validation_request_path(
        planning_application,
        type: "red_line_boundary_change"
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

  def neighbours_layers
    planning_application.consultation && planning_application.consultation.neighbour_responses
      .group_by { |response| response.summary_tag.to_sym }
      .transform_values { |responses| responses.map { |response| RGeo::GeoJSON.encode(response.neighbour.lonlat) }.compact }
      .merge(no_response: unresponsive_neighbours_layer)
  end

  def unresponsive_neighbours_layer
    unresponsive_neighbours = planning_application.consultation.neighbours
      .left_joins(:neighbour_responses).group(:id).having("count(neighbour_responses) = 0")

    unresponsive_neighbours.map { |neighbour| RGeo::GeoJSON.encode(neighbour.lonlat) }.compact
  end
end
