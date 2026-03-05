# frozen_string_literal: true

module Tasks
  class SummaryOfAdditionalEvidenceForm < Form
    include AssessmentDetailConcern

    def category = "additional_evidence"
  end
end
