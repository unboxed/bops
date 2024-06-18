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

  accepts_nested_attributes_for :policy_references, :policy_guidance

  belongs_to :consideration_set
  belongs_to :submitted_by, class_name: "User", optional: true
  acts_as_list scope: :consideration_set

  validates :policy_area, presence: true, uniqueness: {scope: :consideration_set}
  validates :policy_references, presence: true
  validates :assessment, :conclusion, presence: true
end
