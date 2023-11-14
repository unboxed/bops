# frozen_string_literal: true

module TaskListItems
  class AssessImmunityDetailPermittedDevelopmentRightComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:immunity_detail, to: :planning_application)

    def link_text
      t(".immune_permitted_development_rights")
    end

    def link_path
      case status
      when :not_started, :to_be_reviewed
        new_planning_application_assessment_assess_immunity_detail_permitted_development_right_path(
          planning_application
        )
      when :in_progress
        edit_planning_application_assessment_assess_immunity_detail_permitted_development_right_path(
          planning_application
        )
      when :complete
        planning_application_assessment_assess_immunity_detail_permitted_development_right_path(
          planning_application
        )
      else
        raise ArgumentError, "#{status} is not a valid status"
      end
    end

    def status
      if (review_immunity_detail = immunity_detail.current_enforcement_review_immunity_detail)
        review_immunity_detail.status.to_sym
      else
        :not_started
      end
    end
  end
end
