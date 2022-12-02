# frozen_string_literal: true

class ConsistencyChecklist < ApplicationRecord
  belongs_to :planning_application

  CHECKS = %i[
    description_matches_documents
    documents_consistent
    proposal_details_match_documents
    site_map_correct
  ].freeze

  with_options if: :complete? do
    CHECKS.each { |check| validate("#{check}_determined".to_sym) }
    validate :description_change_requests_closed
    validate :additional_document_requests_closed
    validate :red_line_boundary_requests_closed
  end

  enum status: { in_assessment: 0, complete: 1 }, _default: :in_assessment

  CHECKS.each do |check|
    enum(check => { to_be_determined: 0, yes: 1, no: 2 }, _prefix: check)
  end

  private

  CHECKS.each do |check|
    define_method("#{check}_determined") do
      return unless send("#{check}_to_be_determined?")

      errors.add(check, :not_determined)
    end
  end

  def description_change_requests_closed
    return unless planning_application.description_change_validation_requests.open.any?

    errors.add(
      :description_matches_documents,
      :open_description_change_requests
    )
  end

  def red_line_boundary_requests_closed
    return unless planning_application.red_line_boundary_change_validation_requests.open.any?

    errors.add(:site_map_correct, :open_red_line_boundary_requests)
  end

  def additional_document_requests_closed
    return unless planning_application.additional_document_validation_requests.open.any?

    errors.add(:documents_consistent, :open_additional_document_requests)
  end
end
