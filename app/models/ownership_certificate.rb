# frozen_string_literal: true

class OwnershipCertificate < ApplicationRecord
  belongs_to :planning_application
  has_many :land_owners, dependent: :destroy
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  accepts_nested_attributes_for :land_owners

  validates :certificate_type, presence: true

  after_create :create_review

  enum certificate_type: {
    a: "A",
    b: "B",
    c: "C",
    d: "D"
  }

  def current_review
    reviews.where.not(id: nil).order(:created_at).last
  end

  private

  def create_review
    Review.create!(assessor: Current.user, owner_type: "OwnershipCertificate", owner_id: id, status: "not_started")
  end
end
