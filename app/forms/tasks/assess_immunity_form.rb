# frozen_string_literal: true

module Tasks
  class AssessImmunityForm < Form
    include AssessmentDetailConcern

    def category = "assess_immunity"
  end
end
