# frozen_string_literal: true

module BopsCore
  module PlanningApplicationPresenter
    extend ActiveSupport::Concern

    private

    def set_planning_application
      @planning_application = ::PlanningApplicationPresenter.new(view_context, @case_record.caseable)
    end
  end
end
