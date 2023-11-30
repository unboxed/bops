# frozen_string_literal: true

class ReplacementDocumentValidationRequest < ValidationRequest
  belongs_to :old_document, class_name: "Document"
  has_one :new_document, as: :owner, class_name: "Document", dependent: :destroy

  before_create :reset_replacement_document_validation_request_update_counter!
  before_create :set_document_owner
  before_destroy :reset_document_invalidation

  delegate :invalidated_document_reason, to: :old_document
  delegate :validated?, :archived?, to: :new_document, prefix: :new_document

  validates :reason, presence: true

  scope :with_active_document, -> { joins(:old_document).where(documents: {archived_at: nil}) }

  private

  def set_document_owner
    old_document.update(owner: self)
    new_document&.update(owner: self)
  end
end
