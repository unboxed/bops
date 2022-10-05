# frozen_string_literal: true

module AssessmentTasks
  extend ActiveSupport::Concern

  class AssessmentDetailPresenter
    include Presentable

    def initialize(template, planning_application, category)
      @planning_application = planning_application
      @template = template
      @assessment_detail = planning_application.assessment_details.send(category).first
      @status = assessment_details_status
      @category = category
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat assessment_details_link
      end

      html.concat assessment_details_status_tag
    end

    private

    attr_reader :status, :assessment_detail, :category

    def assessment_details_link
      link_to(category_text, assessment_details_link_url, class: "govuk-link")
    end

    def assessment_details_link_url
      case status.humanize

      when "Not started"
        new_planning_application_assessment_detail_path(planning_application, category: category)
      when "In progress"
        edit_planning_application_assessment_detail_path(planning_application, assessment_detail)
      when "Completed"
        planning_application_assessment_detail_path(planning_application, assessment_detail)
      else
        raise ArgumentError, "The status provided: '#{status}' is not valid"
      end
    end

    def assessment_details_status_tag
      classes = ["#{govuk_tag_class} app-task-list__task-tag"]

      tag.strong class: classes do
        status
      end
    end

    def assessment_details_status
      return "Not started" unless assessment_detail

      assessment_detail.status.humanize
    end

    def govuk_tag_class
      return "govuk-tag" unless assessment_information_status_colour

      "govuk-tag govuk-tag--#{assessment_information_status_colour}"
    end

    def assessment_information_status_colour
      case status.humanize

      when "Not started"
        "grey"
      when "Completed"
        "blue"
      when "In progress"
        nil
      else
        raise ArgumentError, "The status provided: '#{status}' is not valid"
      end
    end

    def category_text
      return category.humanize.pluralize if category == "summary_of_work"

      category.humanize
    end
  end
end
