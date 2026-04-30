# frozen_string_literal: true

module BopsCore
  class ConsulteeResponseComponent < ViewComponent::Base
    def initialize(response:, redact_and_publish:, task: nil)
      @response = response
      @redact_and_publish = redact_and_publish
      @task = task
    end

    private

    attr_reader :response, :redact_and_publish, :task

    with_options to: :response do
      delegate :received_at, :summary_tag
      delegate :consultee, :documents
      delegate :published?
    end

    delegate :consultation, to: :consultee
    delegate :planning_application, to: :consultation

    def response_text
      response.response
    end

    def wrapper_tag(&)
      options = {
        id: "consultee-responses-#{response.id}",
        class: "consultee-response"
      }

      content_tag(:div, **options, &)
    end

    def section_break_tag
      tag.hr(class: "govuk-section-break govuk-section-break--l govuk-section-break--visible")
    end

    def received_on
      time_tag(received_at, format: t("consultee_response_component.received_on"))
    end

    def response_status
      case summary_tag
      when "amendments_needed"
        helpers.govuk_tag(text: t("consultee_response_component.amendments_needed"), colour: "yellow")
      when "objected"
        helpers.govuk_tag(text: t("consultee_response_component.objected"), colour: "red")
      when "approved"
        helpers.govuk_tag(text: t("consultee_response_component.approved"), colour: "green")
      end
    end

    def published_status
      if published?
        helpers.govuk_tag(text: t("consultee_response_component.published"), colour: "green")
      else
        helpers.govuk_tag(text: t("consultee_response_component.private"), colour: "grey")
      end
    end

    def redact_and_publish_link_tag
      href = if task
        helpers.edit_planning_application_consultation_consultee_response_path(
          planning_application,
          consultee,
          response,
          task_slug: task.full_slug
        )
      else
        helpers.edit_planning_application_consultee_response_path(planning_application, consultee, response)
      end
      content_tag(:a, t("consultee_response_component.redact_and_publish"), class: "govuk-link", href: href)
    end
  end
end
