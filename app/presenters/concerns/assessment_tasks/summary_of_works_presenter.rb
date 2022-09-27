# frozen_string_literal: true

module AssessmentTasks
  extend ActiveSupport::Concern

  class SummaryOfWorksPresenter < PlanningApplicationPresenter
    def initialize(template, planning_application)
      super(template, planning_application)

      @summary_of_work = planning_application.summary_of_works.first
      @status = summary_of_works_status
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat summary_of_works_link
      end

      html.concat summary_of_works_status_tag
    end

    private

    attr_reader :status, :summary_of_work

    def summary_of_works_link
      link_to("Summary of works", summary_of_works_link_url, class: "govuk-link")
    end

    def summary_of_works_link_url
      case status.humanize

      when "Not started"
        new_planning_application_summary_of_work_path(planning_application)
      when "In progress"
        edit_planning_application_summary_of_work_path(planning_application, summary_of_work)
      when "Completed"
        planning_application_summary_of_work_path(planning_application, summary_of_work)
      else
        raise ArgumentError, "The status provided: '#{status}' is not valid"
      end
    end

    def summary_of_works_status_tag
      classes = ["#{govuk_tag_class} app-task-list__task-tag"]

      tag.strong class: classes do
        status
      end
    end

    def summary_of_works_status
      return "Not started" unless summary_of_work

      summary_of_work.status.humanize
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
  end
end
