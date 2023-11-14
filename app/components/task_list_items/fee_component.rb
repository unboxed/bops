# frozen_string_literal: true

module TaskListItems
  class FeeComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:fee_item_validation_requests, to: :planning_application)

    def link_text
      t(".check_fee")
    end

    def link_path
      case status
      when :valid, :not_started
        planning_application_validation_fee_items_path(
          planning_application,
          validate_fee: :yes
        )
      else
        planning_application_validation_other_change_validation_request_path(
          planning_application,
          fee_item_validation_requests.not_cancelled.last
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
