# frozen_string_literal: true

module AccordionSections
  class PreAssessmentOutcomeComponent < AccordionSections::BaseComponent
    private

    def proposal_details
      @proposal_details ||= planning_application.flagged_proposal_details
    end

    def display_number(proposal_detail)
      planning_application.proposal_details.find_index(proposal_detail) + 1
    end
  end
end
