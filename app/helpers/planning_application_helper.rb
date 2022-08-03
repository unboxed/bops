# frozen_string_literal: true

module PlanningApplicationHelper
  def exclude_others?
    params[:q] == "exclude_others"
  end

  def all_applications_tab_title
    key = exclude_others? ? :all_your_applications : :all_applications
    t(key, scope: "planning_applications.tabs")
  end

  def role_name
    if current_user.assessor?
      t("user.officer_role")
    else
      t("user.manager_role")
    end
  end

  def proposed_or_existing(planning_application)
    planning_application.work_status == "proposed" ? "No" : "Yes"
  end

  def filter_text
    if current_user.assessor?
      "View my applications"
    else
      "View assessed applications"
    end
  end

  def map_link(address)
    "https://google.co.uk/maps/place/#{CGI.escape(address)}"
  end

  def mapit_link(postcode)
    "https://mapit.mysociety.org/postcode/#{postcode.gsub(/\s+/, '').upcase}.html"
  end

  def display_number(proposal_details, element)
    proposal_details.find_index(element) + 1
  end

  def validation_request_summary(validation_requests, planning_application)
    if planning_application.invalidated?
      "This application has #{pluralize(validation_requests.count(&:open?),
                                        'unresolved validation request')} and #{pluralize(
                                          validation_requests.count(&:closed?), 'resolved validation request'
                                        )}"
    elsif planning_application.validation_requests.none? && (planning_application.recommendable? || planning_application.closed_or_cancelled?)
      "This application had no validation requests"
    elsif planning_application.recommendable? || (planning_application.closed_or_cancelled? && planning_application.validation_requests.present?)
      "This application has #{pluralize(validation_requests.count(&:closed?), 'resolved validation request')}"
    else
      # FIXME: same body as first branch
      "This application has #{pluralize(validation_requests.count(&:open?),
                                        'unresolved validation request')} and #{pluralize(
                                          validation_requests.count(&:closed?), 'resolved validation request'
                                        )}"
    end
  end

  def red_line_boundary_post_validation_action_link(planning_application)
    red_line_boundary_change_validation_request = planning_application.red_line_boundary_change_validation_requests.post_validation.last

    case red_line_boundary_change_validation_request.try(:state)
    when "open"
      link_to "View requested red line boundary change", planning_application_red_line_boundary_change_validation_request_path(planning_application, red_line_boundary_change_validation_request), class: "govuk-link"
    when "closed"
      link_to "View applicants response to requested red line boundary change", planning_application_red_line_boundary_change_validation_request_path(planning_application, red_line_boundary_change_validation_request), class: "govuk-link"
    else
      link_to "Request approval for a change to red line boundary", new_planning_application_red_line_boundary_change_validation_request_path(planning_application), class: "govuk-link"
    end
  end

  def show_map_pin?(planning_application, data)
    (data[:geojson].blank? || data[:invalid_red_line_boundary].present?) &&
      planning_application.latitude.present? &&
      planning_application.longitude.present?
  end

  def planning_application_presenters(template, planning_applications)
    planning_applications.map do |planning_application|
      PlanningApplicationPresenter.new(template, planning_application)
    end
  end
end
