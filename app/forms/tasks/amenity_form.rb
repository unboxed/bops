# frozen_string_literal: true

module Tasks
  class AmenityForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    attribute :entry, :string

    after_initialize do
      @assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: "amenity")
      @rejected_assessment_detail = planning_application.rejected_assessment_detail(category: "amenity")
    end

    attr_reader :assessment_detail, :rejected_assessment_detail

    with_options on: %i[save_and_complete save_draft] do
      validates :entry, presence: {message: "Amenity assessment cannot be blank"}
    end

    private

    def save_draft
      transaction do
        @assessment_detail.update!(entry:, assessment_status: :in_progress, user: Current.user)
        super
      end
    end

    def save_and_complete
      transaction do
        @assessment_detail.update!(entry:, assessment_status: :complete, user: Current.user)
        super
      end
    end
  end
end
