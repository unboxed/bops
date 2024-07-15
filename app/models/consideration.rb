# frozen_string_literal: true

class Consideration < ApplicationRecord
  include StoreModel::NestedAttributes

  class PolicyReference
    include StoreModel::Model

    attribute :code, :string
    attribute :description, :string
    attribute :url, :string

    def code_and_description(separator: ": ")
      "#{code}#{separator}#{description}"
    end
  end

  class PolicyGuidance
    include StoreModel::Model

    attribute :description, :string
    attribute :url, :string
  end

  attribute :policy_references, PolicyReference.to_array_type
  attribute :policy_guidance, PolicyGuidance.to_array_type
  attribute :reviewer_edited, :boolean, default: false

  accepts_nested_attributes_for :policy_references, :policy_guidance

  belongs_to :consideration_set
  belongs_to :submitted_by, class_name: "User", optional: true
  acts_as_list scope: :consideration_set

  validates :policy_area, presence: true, uniqueness: {scope: :consideration_set}
  validates :policy_references, presence: true
  validates :assessment, :conclusion, presence: true

  delegate :current_review, to: :consideration_set
  delegate :not_started?, to: :current_review, prefix: true

  before_update if: :reviewer_edited? do
    current_review.update!(reviewer_edited: true)
  end

  after_create if: :current_review_not_started? do
    current_review.update!(status: "in_progress")
  end
end
