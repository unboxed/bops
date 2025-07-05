# frozen_string_literal: true

class AssessImmunityDetailPermittedDevelopmentRightForm
  include ActiveModel::API
  include ActiveModel::Attributes

  IMMUNITY_REASONS = I18n.t(:immunity_reasons).stringify_keys.freeze

  attribute :immunity, :boolean
  attribute :immunity_reason, :string
  attribute :other_immunity_reason, :string
  attribute :summary, :string
  attribute :no_immunity_reason, :string
  attribute :rights_removed, :boolean
  attribute :rights_removed_reason, :string
  attribute :status, :string, default: "complete"

  attr_accessor :planning_application

  validates :immunity, inclusion: {in: [true, false]}

  with_options if: :immunity? do
    validates :immunity_reason, inclusion: {in: IMMUNITY_REASONS.keys}
    validates :other_immunity_reason, presence: true, if: :other_immunity_reason?
    validates :summary, presence: true
  end

  with_options if: :no_immunity? do
    validates :no_immunity_reason, presence: true
    validates :rights_removed, inclusion: {in: [true, false]}
    validates :rights_removed_reason, presence: true, if: :rights_removed?
  end

  define_model_callbacks :initialize, only: :after

  after_initialize do
    if current_review.persisted?
      self.immunity = current_review.decision == "Yes"
      self.immunity_reason = current_review.decision_type
      self.other_immunity_reason = (immunity_reason == "other") ? current_review.decision_reason : nil
      self.summary = current_review.summary
      self.no_immunity_reason = immunity ? nil : current_review.decision_reason
    end

    if permitted_development_right.persisted?
      self.rights_removed = permitted_development_right.removed
      self.rights_removed_reason = rights_removed ? permitted_development_right.removed_reason : nil
    end
  end

  def initialize(attributes = {})
    run_callbacks :initialize do
      super
    end
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

  def no_rights_removed?
    FalseClass === rights_removed
  end

  def immunity_detail
    @immunity_detail ||= planning_application.immunity_detail
  end

  def evidence_groups
    @evidence_groups ||= immunity_detail.evidence_groups
  end

  def permitted_development_right
    @permitted_development_right || planning_application.permitted_development_right
  end

  def permitted_development_rights
    @permitted_development_rights ||= planning_application.permitted_development_rights.returned
  end

  def previous_reviews
    @previous_reviews ||= immunity_detail.reviews.enforcement.reviewer_not_accepted
  end

  def current_review
    @current_review ||= immunity_detail.current_enforcement_review_immunity_detail || immunity_detail.reviews.new
  end

  def update(attributes)
    assign_attributes(attributes)

    ActiveRecord::Base.transaction do
      valid? && update_review! && update_permitted_development_right!
    end
  end

  private

  def update_review!
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
      if immunity_reason == "other"
        other_immunity_reason
      else
        immunity_reasons.fetch(immunity_reason)
      end
    else
      no_immunity_reason
    end
  end

  def update_permitted_development_right!
    return true if immunity?

    permitted_development_right.update!(
      assessor: Current.user,
      status: status,
      removed: (rights_removed ? true : false),
      removed_reason: (rights_removed ? rights_removed_reason : nil)
    )
  end
end
