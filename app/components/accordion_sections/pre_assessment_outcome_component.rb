# frozen_string_literal: true

module AccordionSections
  class PreAssessmentOutcomeComponent < AccordionSections::BaseComponent
    private

    def proposal_details
      @proposal_details ||= planning_application.flagged_proposal_details
    end
  end
end
