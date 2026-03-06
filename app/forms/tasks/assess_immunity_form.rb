# frozen_string_literal: true

module Tasks
  class AssessImmunityForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    IMMUNITY_REASONS = I18n.t(:immunity_reasons).stringify_keys.freeze

    attribute :immunity, :boolean
    attribute :immunity_reason, :string
    attribute :other_immunity_reason, :string
    attribute :summary, :string
    attribute :no_immunity_reason, :string
    attribute :rights_removed, :boolean
    attribute :rights_removed_reason, :string

    after_initialize do
      if current_review.persisted?
        self.immunity = current_review.decision == "Yes"
        self.immunity_reason = current_review.decision_type
        self.other_immunity_reason = (immunity_reason == "other") ? current_review.decision_reason : nil
        self.summary = current_review.summary
        self.no_immunity_reason = immunity ? nil : current_review.decision_reason
      end

      if permitted_development_right&.persisted?
        self.rights_removed = permitted_development_right.removed
        self.rights_removed_reason = rights_removed ? permitted_development_right.removed_reason : nil
      end
    end

    with_options on: :save_and_complete do
      validates :immunity, inclusion: {in: [true, false], message: "Select Yes or No for whether the development is immune"}

      validates :immunity_reason, inclusion: {in: IMMUNITY_REASONS.keys, message: "Select a reason for immunity"}, if: :immunity?
      validates :other_immunity_reason, presence: {message: "Provide a reason for immunity"}, if: :other_immunity_reason?
      validates :summary, presence: {message: "Provide a summary of the immunity assessment"}, if: :immunity?

      validates :no_immunity_reason, presence: {message: "Provide a reason why the development is not immune"}, if: :no_immunity?
      validates :rights_removed, inclusion: {in: [true, false], message: "Select whether permitted development rights have been removed"}, if: :no_immunity?
      validates :rights_removed_reason, presence: {message: "Describe how permitted development rights have been removed"}, if: :rights_removed?
    end

    def immunity_reasons
      IMMUNITY_REASONS
    end

    def immunity?
      TrueClass === immunity
    end

    def other_immunity_reason?
      immunity? && immunity_reason == "other"
    end

    def no_immunity?
      FalseClass === immunity
    end

    def rights_removed?
      no_immunity? && TrueClass === rights_removed
    end

    def immunity_detail
      @immunity_detail ||= planning_application.immunity_detail
    end

    def evidence_groups
      @evidence_groups ||= immunity_detail.evidence_groups
    end

    def permitted_development_right
      @permitted_development_right ||= planning_application.permitted_development_right
    end

    def permitted_development_rights
      @permitted_development_rights ||= planning_application.permitted_development_rights.returned
    end

    def previous_reviews
      @previous_reviews ||= immunity_detail.reviews.enforcement.reviewer_not_accepted
    end

    def current_review
      @current_review ||= immunity_detail.current_enforcement_review || immunity_detail.reviews.new
    end

    private

    def save_draft
      super do
        save_review_draft!
      end
    end

    def save_and_complete
      super do
        update_review!("complete")
        update_permitted_development_right!("complete")
      end
    end

    def save_review_draft!
      current_review.assign_attributes(
        assessor: Current.user,
        status: "in_progress",
        review_type: "enforcement",
        decision: ("Yes" if immunity?) || ("No" if no_immunity?),
        decision_type: immunity? ? immunity_reason : nil,
        decision_reason: decision_reason,
        summary: immunity? ? summary : nil
      )
      current_review.save!(validate: false)
    end

    def update_review!(status)
      current_review.update!(
        assessor: Current.user,
        status: status,
        review_type: "enforcement",
        decision: (immunity ? "Yes" : "No"),
        decision_type: (immunity ? immunity_reason : nil),
        decision_reason: decision_reason,
        summary: immunity ? summary : nil
      )
    end

    def decision_reason
      if immunity
        return nil unless immunity_reason

        if immunity_reason == "other"
          other_immunity_reason
        else
          immunity_reasons.fetch(immunity_reason)
        end
      else
        no_immunity_reason
      end
    end

    def update_permitted_development_right!(status)
      return if immunity?

      permitted_development_right.update!(
        assessor: Current.user,
        status: status,
        removed: (rights_removed ? true : false),
        removed_reason: (rights_removed ? rights_removed_reason : nil)
      )
    end
  end
end
