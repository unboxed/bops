# frozen_string_literal: true

module Tasks
  class SummaryOfAdditionalEvidenceForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    attribute :entry, :string

    after_initialize do
      @assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: "additional_evidence")
    end

    attr_reader :assessment_detail

    with_options on: [:save_and_complete, :save_draft] do
      validate :entry, :presence
    end

    private

    def save_draft
      @assessment_detail.update!(entry:, assessment_status: :in_progress, user: Current.user)
      super
    end

    def save_and_complete
      @assessment_detail.update!(entry:, assessment_status: :complete, user: Current.user)
      super
    end
  end
end
