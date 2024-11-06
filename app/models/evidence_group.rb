# frozen_string_literal: true

class EvidenceGroup < ApplicationRecord
  belongs_to :immunity_detail
  has_many :documents, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  accepts_nested_attributes_for(
    :comments,
    reject_if: :reject_comment?
  )

  enum :tag, {
    "photographs.existing": 0,
    utilityBill: 1,
    buildingControlCertificate: 2,
    constructionInvoice: 3,
    councilTaxBill: 4,
    tenancyAgreement: 5,
    tenancyInvoice: 6,
    bankStatement: 7,
    statutoryDeclaration: 8,
    otherEvidence: 9,
    "photographs.proposed": 10,
    utilitiesStatement: 11
  }

  def comment
    last_comment unless last_comment&.deleted?
  end

  def previous_comments
    persisted_comments - [comment]
  end

  def persisted_comments
    comments.includes(:user).select(&:persisted?).sort_by(&:created_at)
  end

  private

  def last_comment
    @last_comment ||= persisted_comments.last
  end

  def reject_comment?(attributes)
    attributes[:text] == ""
  end
end
