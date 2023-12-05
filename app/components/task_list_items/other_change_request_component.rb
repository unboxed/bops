# frozen_string_literal: true

module TaskListItems
  class OtherChangeRequestComponent < TaskListItems::BaseComponent
    def initialize(planning_application:, request:)
      @planning_application = planning_application
      @request = request
    end

    private

    attr_reader :planning_application, :request

    def link_text
      t(".view_other_validation", number: request.sequence)
    end

    def link_path
      planning_application_validation_other_change_validation_request_path(
        planning_application,
        request
      )
    end

    def status
      if request.open_or_pending?
        :invalid
      elsif request.closed?
        :updated
      end
    end
  end
end
