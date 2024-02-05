# frozen_string_literal: true

class PolicyClass < ApplicationRecord
  belongs_to :planning_application
  has_many :policies, dependent: :destroy
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  accepts_nested_attributes_for :policies, :reviews

  validates :name, :part, :section, :schedule, presence: true

  validate :all_policies_are_determined, if: :complete?

  before_update :maybe_create_review

  def update_required?
    current_review&.to_be_reviewed? && current_review&.review_complete?
  end

  class << self
    def all_parts
      # NOTE: we might do multiple schedules at some point in the
      # future but no need to worry about it now
      I18n.t("schedules").first[:parts]
    end

    def classes_for_part(part)
      all_parts[part.to_i][:classes].map do |attributes|
        PolicyClass.new(attributes)
      end
    end
  end

  def as_json(_options = nil)
    attributes.as_json
  end

  def ==(other)
    if other.is_a? Hash
      part == other[:part] && id == other[:id]
    else
      part == other.part && id == other.id
    end
  end

  def previous
    @previous ||= planning_application.policy_classes.where("section < ?", section).last
  end

  def next
    @next ||= planning_application.policy_classes.where("section > ?", section).first
  end

  def complete?
    return if reviews.empty?

    reviews.last.status == "complete"
  end

  def current_review
    reviews.order(:created_at).last
  end

  def build_review
    Review.build(assessor: Current.user, owner_type: "PolicyClass", owner_id: id)
  end

  private

  def maybe_create_review
    return if current_review.nil?
    return unless current_review.status_changed? && current_review.status_change == %w[to_be_reviewed complete]

    create_review
  end

  def create_review
    Review.create!(assessor: Current.user, owner_type: "PolicyClass", owner_id: id, status: "complete")
  end

  def all_policies_are_determined
    return if policies.none?(&:to_be_determined?)

    errors.add(:base, :policies_to_be_determined)
  end
end
