# frozen_string_literal: true

class ConsulteeOverviewRowComponent < ViewComponent::Base
  def initialize(consultee:)
    @consultee = consultee
  end

  private

  attr_reader :consultee

  delegate :consultation, to: :consultee
  delegate :planning_application, to: :consultation
  delegate :name, to: :consultee, prefix: true
  delegate :last_response, to: :consultee

  def table_row_tag(&)
    options = {
      id: "consultee-#{consultee.id}-overview",
      class: "govuk-table__row"
    }

    content_tag(:tr, **options, &)
  end

  def consultee_url
    if consultee.responses?
      "#consultee-#{consultee.id}-responses"
    else
      new_planning_application_consultee_response_path(planning_application, consultee)
    end
  end

  def consultee_link_tag(&)
    options = {
      class: "govuk-link",
      href: consultee_url
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
    when "awaiting_response"
      content_tag(:span, t(".awaiting_response"), class: "govuk-tag govuk-tag--grey")
    else
      case last_response.summary_tag
      when "amendments_needed"
        content_tag(:span, t(".amendments_needed"), class: "govuk-tag govuk-tag--yellow")
      when "refused"
        content_tag(:span, t(".refused"), class: "govuk-tag govuk-tag--red")
      else
        content_tag(:span, t(".no_objections"), class: "govuk-tag govuk-tag--blue")
      end
    end
  end
end
