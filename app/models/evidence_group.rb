# frozen_string_literal: true

class EvidenceGroup < ApplicationRecord
  belongs_to :immunity_detail
  has_many :documents, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  accepts_nested_attributes_for(
    :comments,
    reject_if: :reject_comment?
  )

  enum tag: {
    photograph: 0,
    utility_bill: 1,
    building_control_certificate: 2,
    construction_invoice: 3,
    council_tax_document: 4,
    tenancy_agreement: 5,
    tenancy_invoice: 6,
    bank_statement: 7,
    statutory_declaration: 8,
    other: 9
  }

  def comment
    last_comment unless last_comment&.deleted?
  end

  def previous_comments
    persisted_comments - [comment]
  end

  private

  def last_comment
    @last_comment ||= persisted_comments.last
  end

  def reject_comment?(attributes)
    attributes[:text] == ""
  end
end
