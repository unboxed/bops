# frozen_string_literal: true

module PlanningApplicationHelper
  def role_name
    if current_user.assessor?
      t("user.officer_role")
    else
      t("user.manager_role")
    end
  end

  def validation_request_summary(validation_requests, planning_application)
    if planning_application.invalidated?
      "This application has #{pluralize(validation_requests.count(&:open?),
        "unresolved validation request")} and #{pluralize(
          validation_requests.count(&:closed?), "resolved validation request"
        )}"
    elsif planning_application.validation_requests.none? &&
        (planning_application.recommendable? || planning_application.closed_or_cancelled?)
      "This application had no validation requests"
    elsif planning_application.recommendable? ||
        (planning_application.closed_or_cancelled? && planning_application.validation_requests.present?)
      "This application has #{pluralize(validation_requests.count(&:closed?), "resolved validation request")}"
    else # rubocop:disable Lint/DuplicateBranch
      # FIXME: same body as first branch
      "This application has #{pluralize(validation_requests.count(&:open?),
        "unresolved validation request")} and #{pluralize(
          validation_requests.count(&:closed?), "resolved validation request"
        )}"
    end
  end

  def show_map_pin?(planning_application, data)
    (data[:geojson].blank? || data[:invalid_red_line_boundary].present?) && planning_application.lonlat.present?
  end

  def map_link(full_address)
    "https://google.co.uk/maps/place/#{CGI.escape(full_address)}"
  end

  def filter_enabled_uniquely?(**args)
    filter = args.keys.first
    value = args[filter]
    filters = (%i[application_type status] - [filter])
    params[filter]&.include?(value) && filters.all? { |param| params[param].blank? }
  end

  def display_or_publish_required?(planning_application, type)
    case type
    when :site
      planning_application.site_notice_needs_displayed_at?
    when :press
      planning_application.press_notice_needs_published_at?
    else
      raise ArgumentError, "Unexpected value for 'type': #{type.inspect}"
    end
  end

  def inactive_local_authority_message
    I18n.t("planning_applications.index.inactive_local_authority")
  end
end
