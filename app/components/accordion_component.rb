# frozen_string_literal: true

class AccordionComponent < ViewComponent::Base
  def initialize(planning_application:, sections: default_sections)
    @planning_application = planning_application
    @sections = sections
  end

  private

  attr_reader :planning_application, :sections

  def section_component(section)
    "AccordionSections::#{section.to_s.camelize}Component".constantize.new(
      planning_application:
    )
  end

  def default_sections
    %i[
      application_information
      site_map
      constraints
      pre_assessment_outcome
      proposal_details
      documents
    ]
  end
end
