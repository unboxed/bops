# frozen_string_literal: true

module Tasks
  class OtherConsiderationsForm < Form
    include AssessmentDetailConcern

    def category = "additional_evidence"
  end
end
