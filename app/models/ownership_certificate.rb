# frozen_string_literal: true

class OwnershipCertificate < ApplicationRecord
  belongs_to :planning_application
  has_many :land_owners

  enum certificate_type: {
    a: "A",
    b: "B",
    c: "C",
    d: "D"
  }
end
