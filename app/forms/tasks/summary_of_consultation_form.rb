# frozen_string_literal: true

module Tasks
  class SummaryOfConsultationForm < Form
    include AssessmentDetailConcern

    def category = "consultation_summary"
  end
end
