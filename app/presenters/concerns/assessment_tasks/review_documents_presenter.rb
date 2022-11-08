# frozen_string_literal: true

module AssessmentTasks
  extend ActiveSupport::Concern

  class ReviewDocumentsPresenter
    include Presentable

    def initialize(template, planning_application)
      @planning_application = planning_application
      @template = template
      @status = planning_application.review_documents_for_recommendation_status
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat review_documents_link
      end

      html.concat review_documents_status_tag
    end

    private

    attr_reader :status

    def review_documents_link
      link_to(
        "Review documents for recommendation",
        planning_application_review_documents_path(planning_application), class: "govuk-link"
      )
    end

    def review_documents_status_tag
      classes = ["#{govuk_tag_class} app-task-list__task-tag"]

      tag.strong class: classes do
        I18n.t("status_tag_component.#{status}")
      end
    end

    def govuk_tag_class
      return "govuk-tag" unless status_colour

      "govuk-tag govuk-tag--#{status_colour}"
    end

    def status_colour
      case status.humanize

      when "Not started"
        "grey"
      when "Complete"
        "blue"
      when "In progress"
        nil
      else
        raise ArgumentError, "The status provided: '#{status}' is not valid"
      end
    end
  end
end
