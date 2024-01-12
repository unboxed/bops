# frozen_string_literal: true

module TaskListItems
  class OtherChangeRequestComponent < TaskListItems::BaseComponent
    def initialize(planning_application:, request_id:, request_sequence:, request_status:)
      @planning_application = planning_application
      @request_id = request_id
      @request_sequence = request_sequence
      @request_status = request_status
    end

    private

    attr_reader :planning_application, :request_id, :request_sequence, :request_status

    def link_text
      t(".view_other_validation", number: request_sequence)
    end

    def link_path
      planning_application_validation_other_change_validation_request_path(
        planning_application,
        request_id
      )
    end

    def status
      if request_status == "open" || request_status == "pending"
        :invalid
      elsif request_status == "closed"
        :updated
      end
    end
  end
end
