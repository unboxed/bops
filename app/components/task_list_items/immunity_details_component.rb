# frozen_string_literal: true

module TaskListItems
  class ImmunityDetailsComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".evidence_of_immunity")
    end

    def link_path
      case status
      when :not_started
        new_planning_application_immunity_detail_path(
          planning_application
        )
      when :in_progress
        edit_planning_application_immunity_detail_path(
          planning_application,
          planning_application.immunity_detail
        )
      when :complete
        planning_application_immunity_detail_path(
          planning_application,
          planning_application.immunity_detail
        )
      end
    end

    def status
      if planning_application.immunity_detail.blank?
        :not_started
      elsif to_be_reviewed?
        :to_be_reviewed
      else
        planning_application.immunity_detail.status.to_sym
      end
    end

    def to_be_reviewed?
      planning_application.recommendation&.rejected? &&
        permitted_development_right.update_required?
    end
  end
end
