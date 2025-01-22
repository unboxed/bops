# frozen_string_literal: true

module BopsConsultees
  class PlanningApplicationPresenter
    include Presentable

    presents :planning_application

    include BopsCore::StatusPresenter

    def initialize(template, planning_application)
      @template = template
      @planning_application = planning_application
    end
  end
end
