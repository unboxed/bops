# frozen_string_literal: true

module TaskListItems
  class ConditionsComponent < TaskListItems::BaseComponent
    def initialize(condition_set:)
      @condition_set = condition_set
    end

    private

    attr_reader :condition_set
    delegate :planning_application_id, to: :condition_set

    def link_text
      "Add conditions"
    end

    def link_path
      planning_application_conditions_path(planning_application_id)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status:)
    end

    def status
      condition_set.status
    end
  end
end
