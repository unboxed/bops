# frozen_string_literal: true

class ConsulteeOverviewRowComponent < ViewComponent::Base
  def initialize(consultee:)
    @consultee = consultee
  end

  private

  attr_reader :consultee

  delegate :consultation, to: :consultee
  delegate :planning_application, to: :consultation
  delegate :last_response, to: :consultee

  def table_row_tag(&)
    options = {
      id: "consultee-#{consultee.id}-overview",
      class: "govuk-table__row"
    }

    content_tag(:tr, **options, &)
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

  def consultee_link_tag(&)
    options = {
      class: "govuk-link",
      href: "#consultee-#{consultee.id}-responses"
    }

    content_tag(:a, **options, &)
  end

  def consultee_email_sent_at
    consultee.email_sent_at.to_fs(:day_month_year_slashes)
  end

  def consultee_expires_at
    consultee.expires_at.to_fs(:day_month_year_slashes)
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
      case last_response.summary_tag
      when "amendments_needed"
        content_tag(:span, t(".amendments_needed"), class: "govuk-tag govuk-tag--yellow")
      when "objected"
        content_tag(:span, t(".objected"), class: "govuk-tag govuk-tag--red")
      when "approved"
        content_tag(:span, t(".approved"), class: "govuk-tag govuk-tag--green")
      end
    end
  end
end
