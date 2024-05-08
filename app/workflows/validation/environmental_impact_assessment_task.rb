# frozen_string_literal: true

module Validation
  class EnvironmentalImpactAssessmentTask < WorkflowTask
    def task_list_link_text
      "Check Environment Impact Assessment"
    end

    def task_list_link
      if planning_application.environment_impact_assessment.nil?
        new_planning_application_validation_environment_impact_assessment_path(planning_application)
      else
        planning_application_validation_environment_impact_assessment_path(planning_application)
      end
    end

    def task_list_status
      planning_application.environment_impact_assessment_status
    end
  end
end
