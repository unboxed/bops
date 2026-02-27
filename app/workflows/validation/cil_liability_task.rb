# frozen_string_literal: true

module Validation
  class CilLiabilityTask < WorkflowTask
    def task_list_link_text
      "Confirm Community Infrastructure Levy (CIL)"
    end

    def task_list_link
      edit_planning_application_validation_cil_liability_path(@planning_application)
    end

    def task_list_status
      case planning_application.cil_liable
      when TrueClass, FalseClass
        :complete
      when NilClass
        :not_started
      end
    end
  end
end
