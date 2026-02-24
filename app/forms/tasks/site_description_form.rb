# frozen_string_literal: true

module Tasks
  class SiteDescriptionForm < Form
    self.task_actions = %w[save_and_complete save_draft edit_form]

    attribute :entry, :string

    after_initialize do
      @assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: "site_description")
    end

    attr_reader :assessment_detail

    with_options on: %i[save_and_complete save_draft] do
      validates :entry, presence: {message: "Site description cannot be blank"}
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
