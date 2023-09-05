# frozen_string_literal: true

module TaskListItems
  class CilLiabilityComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:cil_liable, to: :planning_application)

    def link_text
      t(".link_text")
    end

    def link_path
      edit_planning_application_cil_liability_path(
        planning_application
      )
    end

    def status
      case cil_liable
      when TrueClass
        :cil_liable
      when FalseClass
        :not_cil_liable
      when NilClass
        :not_started
      else
        raise "Unexpected value for `cil_liable': #{cil_liable.inspect}"
      end
    end
  end
end
