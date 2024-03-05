# frozen_string_literal: true

module ValidationTasks
  extend ActiveSupport::Concern

  class ItemsCounterPresenter < PlanningApplicationPresenter
    def initialize(template, planning_application)
      super(template, planning_application)

      @validation_requests = planning_application.validation_requests.active
    end

    def items_count
      {
        invalid: invalid_items_count.to_s,
        updated: updated_items_count.to_s
      }
    end

    private

    attr_reader :validation_requests

    def validation_requests_not_time_extension
      validation_requests.select { |request| request.type != "TimeExtensionValidationRequest" }
    end

    def invalid_items_count
      validation_requests_not_time_extension.count(&:open_or_pending?)
    end

    def updated_items_count
      planning_application.validation_requests.where(update_counter: true).length
    end
  end
end
