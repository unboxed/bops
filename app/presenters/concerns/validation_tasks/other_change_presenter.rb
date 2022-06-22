# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class OtherChangePresenter < PlanningApplicationPresenter
    attr_reader :other_change_validation_request

    def initialize(template, planning_application, other_change_validation_request)
      super(template, planning_application)

      @other_change_validation_request = other_change_validation_request
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat link_to "View other validation request ##{other_change_validation_request.sequence}",
                       planning_application_other_change_validation_request_path(
                         planning_application, other_change_validation_request
                       ), class: "govuk-link"
      end

      html.concat validation_item_tag
    end

    private

    def validation_item_status
      status = if other_change_validation_request.open_or_pending?
                 "Invalid"
               elsif other_change_validation_request.closed?
                 "Updated"
               end

      raise "Status: #{status} is not included in the permitted list" unless STATUSES.include?(status)

      status
    end
  end
end
