# frozen_string_literal: true

module EvidenceGroups
  class ReviewAccordionComponent < ViewComponent::Base
    include ApplicationHelper

    def initialize(planning_application:, sections: default_sections)
      @planning_application = planning_application
      @sections = sections
    end

    def new_comment
      @new_comment ||= sections.first.comments.first
    end

    private

    attr_reader :planning_application, :sections
  end
end
