# frozen_string_literal: true

class ConsulteesTableComponent < ViewComponent::Base
  def initialize(consultees:)
    @consultees = consultees
  end

  private

  attr_reader :consultees

  def consultee_name(consultee)
    if consultee.suffix?
      content_tag(:div) do
        concat(consultee.name + " ")
        concat(tag.br)
        concat(content_tag(:span, consultee.suffix, class: "govuk-!-font-size-16"))
      end
    else
      view_context.content_tag(:div, consultee.name)
    end
  end

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

  def toggle_all_tag
    name = "toggle-consultees"
    value = "1"
    checked = consultees.all?(&:selected?)

    options = {
      class: "govuk-checkboxes__input",
      name: nil,
      data: {
        action: "change->consultees#toggleConsultees"
      }
    }

    check_box_tag(name, value, checked, **options)
  end

  def consultee_constraint(consultee)
    consultee.planning_application_constraints.map(&:type_code).to_sentence.presence || "&ndash;".html_safe
  end

  def consultee_date_consulted(consultee)
    consultee.email_delivered_at? ? consultee.email_delivered_at.to_fs(:day_month_year_slashes) : "&ndash;".html_safe
  end

  def consultee_status(consultee)
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
