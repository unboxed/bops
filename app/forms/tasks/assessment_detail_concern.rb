# frozen_string_literal: true

module Tasks
  module AssessmentDetailConcern
    extend ActiveSupport::Concern

    included do
      self.task_actions = %w[save_and_complete save_draft]

      attribute :entry, :string

      after_initialize do
        @assessment_detail = planning_application.assessment_details.find_or_initialize_by(category:)
        @rejected_assessment_detail = planning_application.rejected_assessment_detail(category:)
      end

      attr_reader :assessment_detail, :category, :rejected_assessment_detail

      with_options on: %i[save_and_complete save_draft] do
        validates :entry, presence: true
      end
    end

    private

    def category = nil

    def save_draft
      super do
        build_or_update_assessment_detail!(assessment_status: :in_progress)
      end
    end

    def save_and_complete
      super do
        build_or_update_assessment_detail!(assessment_status: :complete)
      end
    end

    def build_or_update_assessment_detail!(assessment_status:)
      if @rejected_assessment_detail.present?
        @assessment_detail = planning_application.assessment_details.create!(
          category:, entry:, assessment_status:, user: Current.user
        )
      else
        @assessment_detail.update!(entry:, assessment_status:, user: Current.user)
      end
    end
  end
end
