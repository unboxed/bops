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
      build_or_update_assessment_detail!(assessment_status: :in_progress)
      super
    end

    def save_and_complete
      build_or_update_assessment_detail!(assessment_status: :complete)
      super
    end

    def build_or_update_assessment_detail!(assessment_status:)
      if @rejected_assessment_detail.present?
        @assessment_detail = planning_application.assessment_details.create!(
          category: "amenity", entry:, assessment_status:, user: Current.user
        )
      else
        @assessment_detail.update!(entry:, assessment_status:, user: Current.user)
      end
    end
  end
end
