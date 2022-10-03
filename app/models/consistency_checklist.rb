# frozen_string_literal: true

class ConsistencyChecklist < ApplicationRecord
  belongs_to :planning_application

  with_options if: :complete? do
    validate :description_matches_documents_determined
    validate :proposal_details_match_documents_determined
    validate :documents_consistent_determined
    validate :description_change_requests_closed
    validate :additional_document_requests_closed
  end

  enum status: { in_assessment: 0, complete: 1 }, _default: :in_assessment

  enum(
    description_matches_documents: {
      to_be_determined: 0,
      yes: 1,
      no: 2
    },
    _default: :to_be_determined,
    _prefix: :description_matches_documents
  )

  enum(
    documents_consistent: {
      to_be_determined: 0,
      yes: 1,
      no: 2
    },
    _default: :to_be_determined,
    _prefix: :documents_consistent
  )

  enum(
    proposal_details_match_documents: {
      to_be_determined: 0,
      yes: 1,
      no: 2
    },
    _default: :to_be_determined,
    _prefix: :proposal_details_match_documents
  )

  private

  def description_matches_documents_determined
    return unless description_matches_documents_to_be_determined?

    errors.add(:description_matches_documents, :not_determined)
  end

  def proposal_details_match_documents_determined
    return unless proposal_details_match_documents_to_be_determined?

    errors.add(:proposal_details_match_documents, :not_determined)
  end

  def documents_consistent_determined
    return unless documents_consistent_to_be_determined?

    errors.add(:documents_consistent, :not_determined)
  end

  def description_change_requests_closed
    return unless open_description_change_requests?

    errors.add(
      :description_matches_documents,
      :open_description_change_requests
    )
  end

  def additional_document_requests_closed
    return unless open_additional_document_requests?

    errors.add(:documents_consistent, :open_additional_document_requests)
  end

  def open_description_change_requests?
    planning_application.description_change_validation_requests.open.any?
  end

  def open_additional_document_requests?
    planning_application.additional_document_validation_requests.open.any?
  end
end
