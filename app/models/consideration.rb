# frozen_string_literal: true

class Consideration < ApplicationRecord
  include StoreModel::NestedAttributes

  class PolicyReference
    include StoreModel::Model

    attribute :code, :string
    attribute :description, :string
    attribute :url, :string

    def code_and_description(separator: ": ")
      code.present? ? "#{code}#{separator}#{description}" : description
    end
  end

  class PolicyGuidance
    include StoreModel::Model

    attribute :description, :string
    attribute :url, :string
  end

  enum :summary_tag, %i[complies needs_changes does_not_comply].index_with(&:to_s)

  attribute :policy_references, PolicyReference.to_array_type
  attribute :policy_guidance, PolicyGuidance.to_array_type
  attribute :reviewer_edited, :boolean, default: false

  accepts_nested_attributes_for :policy_references, :policy_guidance

  belongs_to :consideration_set
  belongs_to :submitted_by, class_name: "User", optional: true
  acts_as_list scope: :consideration_set

  validates :policy_area, presence: true
  validates :policy_area, uniqueness: {scope: :consideration_set}, if: :draft
  validates :policy_references, presence: true, unless: :draft

  delegate :current_review, to: :consideration_set
  delegate :not_started?, to: :current_review, prefix: true

  scope :active, -> { where(draft: false) }

  before_update if: :reviewer_edited? do
    current_review.update!(reviewer_edited: true)
  end

  after_create if: :current_review_not_started? do
    current_review.update!(status: "in_progress")
  end

  with_options on: :assess do
    validates :assessment, :conclusion, presence: true
  end

  with_options on: :advice do
    validates :proposal, :summary_tag, :policy_references, presence: true, unless: :draft
  end
end
