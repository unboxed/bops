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
    if consultee.suffix?
      content_tag(:div) do
        concat(consultee.name + " ")
        concat(tag.br)
        concat(content_tag(:span, consultee.suffix, class: "govuk-!-font-size-16"))
      end
    else
      content_tag(:div, consultee.name)
    end
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
      content_tag(:span, t(".sending"), class: "govuk-tag govuk-tag--grey")
    when "failed"
      content_tag(:span, t(".failed"), class: "govuk-tag govuk-tag--red")
    when "awaiting_response"
      content_tag(:span, t(".awaiting_response"), class: "govuk-tag govuk-tag--grey")
    when "responded"
      content_tag(:span, t(".responded"), class: "govuk-tag govuk-tag--blue")
    else
      content_tag(:span, t(".not_consulted"), class: "govuk-tag govuk-tag--grey")
    end
  end
end
