# frozen_string_literal: true

module Tasks
  class SummaryOfWorksForm < Form
    include AssessmentDetailConcern

    def category = "summary_of_work"
  end
end
