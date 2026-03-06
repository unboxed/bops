# frozen_string_literal: true

module EvidenceGroups
  class AccordionComponent < ViewComponent::Base
    include ApplicationHelper

    def initialize(planning_application:, editable:, sections: default_sections, url: nil, show_submit_buttons: true)
      @planning_application = planning_application
      @sections = sections
      @editable = editable
      @url = url
      @show_submit_buttons = show_submit_buttons
    end

    private

    attr_reader :planning_application, :sections, :editable, :url, :show_submit_buttons
  end
end
