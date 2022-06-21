# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class ReviewPresenter < PlanningApplicationPresenter
    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat link_to "Send validation decision",
                       validation_decision_planning_application_path(@planning_application), class: "govuk-link"
      end

      html.concat validation_item_tag
    end

    private

    def validation_item_status
      status = if planning_application.validated?
                 "Valid"
               elsif planning_application.invalidated?
                 "Invalid"
               else
                 "Not started"
               end

      raise "Status: #{status} is not included in the permitted list" unless STATUSES.include?(status)

      status
    end
  end
end
