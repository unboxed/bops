# frozen_string_literal: true

class OwnershipCertificate < ApplicationRecord
  belongs_to :planning_application
  has_many :land_owners, dependent: :destroy

  accepts_nested_attributes_for :land_owners

  validates :certificate_type, presence: true

  enum certificate_type: {
    a: "A",
    b: "B",
    c: "C",
    d: "D"
  }
end
