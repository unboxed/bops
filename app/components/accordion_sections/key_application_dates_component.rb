# frozen_string_literal: true

module AccordionSections
  class KeyApplicationDatesComponent < AccordionSections::BaseComponent
    def valid_from
      planning_application.valid_from&.to_date || t(".not_yet_valid")
    end
  end
end
