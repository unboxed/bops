# frozen_string_literal: true

module TaskListItems
  class PermittedDevelopmentRightComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:permitted_development_right, to: :planning_application)

    def link_text
      t(".permitted_development_rights")
    end

    def link_path
      case status
      when :not_started, :to_be_reviewed
        new_planning_application_permitted_development_right_path(
          planning_application
        )
      when :in_progress
        edit_planning_application_permitted_development_right_path(
          planning_application,
          permitted_development_right
        )
      when :checked, :removed
        planning_application_permitted_development_right_path(
          planning_application,
          permitted_development_right
        )
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: status)
    end

    def status
      @status ||= permitted_development_right&.status&.to_sym || :not_started
    end
  end
end
