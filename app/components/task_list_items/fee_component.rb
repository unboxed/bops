# frozen_string_literal: true

module TaskListItems
  class FeeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".check_fee")
    end

    def fee_item_validation_requests
      @planning_application.validation_requests.where(request_type: "fee_change")
    end

    def link_path
      case status
      when :valid, :not_started
        planning_application_validation_fee_items_path(
          planning_application
        )
      else
        planning_application_validation_validation_request_path(
          planning_application,
          fee_item_validation_requests.not_cancelled.last,
          request_type: "fee_change"
        )
      end
    end

    def status
      @status ||= if planning_application.valid_fee?
        :valid
      elsif fee_item_validation_requests.open_or_pending.any?
        :invalid
      elsif fee_item_validation_requests.closed.any?
        :updated
      else
        :not_started
      end
    end
  end
end
