# frozen_string_literal: true

module PlanningApplicationHelper
  def planning_application_notification_banner(planning_application)
    return unless current_user

    heading =
      if planning_application.pre_application? && planning_application.determined?
        "This report has been sent to the applicant."
      elsif planning_application.closed_or_cancelled?
        "This application has been #{planning_application.status}."
      end

    return unless heading

    render(
      "shared/notification_banner",
      banner_class: "govuk-notification-banner",
      title: "Important",
      heading: heading
    )
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

  def appeal_link_and_translation(planning_application)
    if planning_application.appeal_lodged?
      [".update_appeal", edit_planning_application_appeal_validate_path(planning_application)]
    elsif planning_application.appeal_validated?
      [".update_appeal", edit_planning_application_appeal_start_path(planning_application)]
    elsif planning_application.appeal_started? || planning_application.appeal_determined?
      [".update_appeal", edit_planning_application_appeal_decision_path(planning_application)]
    else
      [".mark_for_appeal", new_planning_application_appeal_path(planning_application)]
    end
  end

  def consultation_task_title(planning_application)
    if planning_application.neighbour_consultation_feature? && planning_application.publishable?
      "Consultees, neighbours and publicity"
    elsif planning_application.publishable?
      "Consultees and publicity"
    elsif planning_application.neighbour_consultation_feature?
      "Consultees and neighbours"
    else
      "Consultees"
    end
  end

  def heads_of_terms_task_header(planning_application)
    planning_application.pre_application? ? "Suggest heads of terms" : "Add heads of terms"
  end

  def planning_applications_tab_routes
    {
      mine: :mine_planning_applications_path,
      unassigned: :unassigned_planning_applications_path,
      closed: :closed_planning_applications_path,
      updated: :updated_planning_applications_path,
      all: :all_planning_applications_path
    }.freeze
  end
end
