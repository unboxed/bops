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

  def replace_document!(file:, reason:)
    transaction do
      self.new_document = planning_application.documents.create!(
        file:,
        tags: old_document.tags,
        numbers: old_document.numbers,
        owner: self
        )
        
        close!
        old_document.update!(archive_reason: reason, archived_at: Time.zone.now)
      end
  end

  private

  def set_document_owner
    new_document&.update(owner: self)
  end

  def audit_comment
    {old_document: old_document.name,
     applicant_reason: invalidated_document_reason}.to_json
  end

  def audit_api_comment
    new_document.name
  end
end
