# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class FeeItemsPresenter < PlanningApplicationPresenter
    attr_reader :fee_item_validation_request

    def initialize(template, planning_application)
      super(template, planning_application)

      @fee_item_validation_request = planning_application.fee_item_validation_requests.not_cancelled.last
    end

    def task_list_row
      html = tag.span class: "app-task-list__task-name" do
        concat validate_link
      end

      html.concat validation_item_tag
    end

    private

    def validate_link
      case validation_item_status
      when "Valid", "Not checked yet"
        link_to "Validate fee",
                planning_application_fee_items_path(planning_application, validate_fee: "yes"), class: "govuk-link"
      when "Invalid", "Updated"
        link_to "Validate fee",
                planning_application_other_change_validation_request_path(
                  planning_application, fee_item_validation_request
                ), class: "govuk-link"
      else
        raise ArgumentError, "Status: #{validation_item_status} is not a valid option"
      end
    end

    def validation_item_status
      status = if planning_application.valid_fee?
                 "Valid"
               elsif planning_application.fee_item_validation_requests.open_or_pending.any?
                 "Invalid"
               elsif planning_application.fee_item_validation_requests.closed.any?
                 "Updated"
               else
                 "Not checked yet"
               end

      raise "Status: #{status} is not included in the permitted list" unless STATUSES.include?(status)

      status
    end
  end
end
