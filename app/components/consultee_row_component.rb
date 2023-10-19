# frozen_string_literal: true

class ConsulteeRowComponent < ViewComponent::Base
  def initialize(consultee:)
    @consultee = consultee
  end

  private

  attr_reader :consultee

  def record_name
    "consultation[consultees_attributes]"
  end

  def table_row_tag
    fields_for(record_name, consultee, index: consultee.id) do |fields|
      options = {
        id: dom_id(consultee),
        class: "govuk-table__row"
      }

      content_tag(:tr, **options) { yield fields }
    end
  end

  def consultee_name
    consultee.name
  end

  def consultee_period
    if consultee.expired?
      content_tag(:span, pluralize(consultee.period, "day"), class: "expired")
    elsif consultee.email_delivered_at?
      pluralize(consultee.period, "day")
    end
  end

  def consultee_date_consulted
    consultee.email_delivered_at? && consultee.email_delivered_at.to_fs(:day_month_year_slashes)
  end

  def consultee_status
    case consultee.status
    when "sending"
      content_tag(:span, t(".sending"), class: "govuk-tag govuk-tag--blue")
    when "failed"
      content_tag(:span, t(".failed"), class: "govuk-tag govuk-tag--red")
    when "consulted"
      content_tag(:span, t(".consulted"), class: "govuk-tag govuk-tag--green")
    else
      content_tag(:span, t(".not_consulted"), class: "govuk-tag govuk-tag--grey")
    end
  end
end
