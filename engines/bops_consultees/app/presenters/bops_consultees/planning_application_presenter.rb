# frozen_string_literal: true

module BopsConsultees
  class PlanningApplicationPresenter
    include BopsCore::Presentable

    presents :planning_application

    include BopsCore::StatusPresenter
    include ActionView::Helpers::SanitizeHelper

    def initialize(template, planning_application)
      @template = template
      @planning_application = planning_application
    end
  end
end
