# frozen_string_literal: true

class PolicyClass < ApplicationRecord
  belongs_to :planning_application
  has_many :policies, dependent: :destroy
  has_one :review_policy_class, dependent: :destroy

  accepts_nested_attributes_for :policies, :review_policy_class

  validates :name, :part, :section, :schedule, presence: true

  validate :all_policies_are_determined, if: :complete?

  enum status: { in_assessment: 0, complete: 1, to_be_reviewed: 2 }, _default: :in_assessment

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

  private

  def all_policies_are_determined
    return if policies.none?(&:to_be_determined?)

    errors.add(:status, :policies_to_be_determined)
  end
end
