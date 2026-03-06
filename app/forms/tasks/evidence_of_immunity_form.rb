# frozen_string_literal: true

module Tasks
  class EvidenceOfImmunityForm < Form
    include AssessmentDetailConcern

    def category = "evidence_of_immunity"
  end
end
