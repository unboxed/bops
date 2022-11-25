# frozen_string_literal: true

module TaskListItems
  class AssessmentDetailComponent < TaskListItems::BaseComponent
    def initialize(planning_application:, category:)
      @planning_application = planning_application
      @category = category
    end

    private

    attr_reader :planning_application, :category

    def link_text
      t(".#{category}")
    end

    def link_path
      case status
      when :not_started, :to_be_reviewed
        new_planning_application_assessment_detail_path(
          planning_application,
          category: category
        )
      when :in_progress
        edit_planning_application_assessment_detail_path(
          planning_application,
          assessment_detail
        )
      else
        planning_application_assessment_detail_path(
          planning_application,
          assessment_detail
        )
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: status)
    end

    def status
      if assessment_detail.blank?
        :not_started
      elsif assessment_detail.assessment_in_progress?
        :in_progress
      elsif update_required?
        :to_be_reviewed
      else
        :complete
      end
    end

    def update_required?
      planning_application.recommendation&.rejected? &&
        assessment_detail.update_required?
    end

    def assessment_detail
      @assessment_detail || planning_application.send(category)
    end
  end
end
