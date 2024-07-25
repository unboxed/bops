# frozen_string_literal: true

module AccordionSections
  class ConsiderationsComponent < AccordionSections::BaseComponent
    delegate :consideration_set, to: :planning_application
    delegate :considerations, to: :consideration_set
  end
end
