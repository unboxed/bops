# frozen_string_literal: true

class ConsulteePresenter
  STATUSES = {
    not_consulted: {label: "Not consulted", modifier: "govuk-tag--grey"},
    not_required: {label: "Not required", modifier: "govuk-tag--grey"},
    sending: {label: "Sending", modifier: "govuk-tag--grey"},
    failed: {label: "Delivery failed", modifier: "govuk-tag--red"},
    awaiting_response: {label: "Awaiting response", modifier: "govuk-tag--yellow"},
    no_objection: {label: "No objection", modifier: "govuk-tag--green"},
    amendments_needed: {label: "Amendments needed", modifier: "govuk-tag--yellow"},
    objection: {label: "Objection", modifier: "govuk-tag--red"}
  }.freeze

  RESPONDED_STATUS_MAP = {
    "approved" => :no_objection,
    "amendments_needed" => :amendments_needed,
    "objected" => :objection
  }.freeze

  attr_reader :consultee, :planning_application, :view_context

  delegate :internal?, :responses, to: :consultee

  def initialize(consultee, planning_application:, view_context:)
    @consultee = consultee
    @planning_application = planning_application
    @view_context = view_context
  end

  def name
    consultee.name
  end

  def role_line
    [consultee.role, consultee.organisation].compact_blank.join(", ").presence
  end

  def status_key
    @status_key ||= case consultee.status.to_s
    when "responded"
      RESPONDED_STATUS_MAP.fetch(last_response_summary_tag, :awaiting_response)
    when "awaiting_response"
      :awaiting_response
    when "not_consulted"
      :not_consulted
    when "not_required"
      :not_required
    when "sending"
      :sending
    when "failed"
      :failed
    else
      :awaiting_response
    end
  end

  def status_label
    status_config[:label]
  end

  def status_tag
    view_context.tag.span(status_label, class: ["govuk-tag", status_config[:modifier]].compact.join(" "))
  end

  def type_label
    if internal?
      view_context.t("planning_applications.consultee.type.internal", default: "Internal")
    else
      view_context.t("planning_applications.consultee.type.external", default: "External")
    end
  end

  def type_tag
    view_context.tag.span(type_label, class: "govuk-tag govuk-tag--grey")
  end

  def summary_tag
    last_response_summary_tag
  end

  def category
    case status_key
    when :no_objection
      :no_objection
    when :amendments_needed
      :amendments_needed
    when :objection
      :objection
    else
      :other
    end
  end

  def no_objection?
    category == :no_objection
  end

  def amendments_needed?
    category == :amendments_needed
  end

  def objection?
    category == :objection
  end

  def responses_count
    responses.size
  end

  def has_responses?
    responses_count.positive?
  end

  def response_snippet
    body = latest_response_body
    return if body.blank?

    view_context.truncate(view_context.strip_tags(body), length: 200, omission: "…")
  end

  def fallback_response_text
    I18n.t("planning_applications.consultee.responses.no_responses", default: "No responses received yet.")
  end

  def last_corresponded_at
    if last_received_at.present?
      I18n.t("planning_applications.consultee.responses.last_received", date: format_date(last_received_at))
    elsif last_contacted_at.present?
      I18n.t("planning_applications.consultee.responses.last_contacted", date: format_date(last_contacted_at))
    end
  end

  def view_all_responses_label
    I18n.t("consultee_responses_component.view_all_responses", count: responses_count)
  end

  def upload_new_response_label
    I18n.t("consultee_responses_component.upload_new_response")
  end

  def view_all_responses_path
    view_context.planning_application_consultee_path(planning_application, consultee)
  end

  def upload_new_response_path
    view_context.new_planning_application_consultee_response_path(planning_application, consultee)
  end

  def dom_id(prefix = :panel)
    view_context.dom_id(consultee, prefix)
  end

  private

  def status_config
    STATUSES.fetch(status_key) { STATUSES[:awaiting_response] }
  end

  def last_response
    consultee.last_response
  end

  def last_response_summary_tag
    last_response&.summary_tag
  end

  def latest_response_body
    last_response&.response
  end

  def last_received_at
    consultee.last_received_at || consultee.last_response_at
  end

  def last_contacted_at
    consultee.last_email_sent_at || consultee.last_email_delivered_at || consultee.email_sent_at || consultee.email_delivered_at
  end

  def format_date(value)
    return "–" if value.blank?

    date_value = value.respond_to?(:to_date) ? value.to_date : value
    date_value.to_fs(:day_month_year)
  end
end
