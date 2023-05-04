# frozen_string_literal: true

module EvidenceGroups
  class AccordionComponent < ViewComponent::Base
    include ApplicationHelper

    def initialize(planning_application:, editable:, sections: default_sections)
      @planning_application = planning_application
      @sections = sections
      @editable = editable
    end

    private

    attr_reader :planning_application, :sections, :editable
  end
end
