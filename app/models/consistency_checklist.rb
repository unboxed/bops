# frozen_string_literal: true

class ConsistencyChecklist < ApplicationRecord
  include Memoizable
  belongs_to :planning_application

  CHECKS = %i[
    description_matches_documents
    documents_consistent
    proposal_details_match_documents
    proposal_measurements_match_documents
    site_map_correct
  ].freeze

  REQUEST_TYPES = {
    description_matches_documents: :description_change,
    documents_consistent: :additional_document,
    site_map_correct: :red_line_boundary_change
  }.freeze

  with_options if: :complete? do
    CHECKS.each { |check| validate("#{check}_determined".to_sym) }

    REQUEST_TYPES.each_value do |request_type|
      validate("#{request_type}_requests_closed".to_sym)
    end
  end

  enum status: {in_assessment: 0, complete: 1}, _default: :in_assessment

  CHECKS.each do |check|
    enum(check => {to_be_determined: 0, yes: 1, no: 2}, :_prefix => check)
  end

  REQUEST_TYPES.each do |check, request_type|
    # defines #default_description_matches_documents_to_no?,
    # #default_documents_consistent_to_no?,
    # #default_site_map_correct_to_no?
    define_method("default_#{check}_to_no?") do
      send("open_#{request_type}_requests?") || send("#{check}_no?")
    end

    # defines #open_description_change_requests?,
    # #open_additional_document_requests?,
    # #open_red_line_boundary_change_requests?
    define_method("open_#{request_type}_requests?") do
      planning_application.send("#{request_type}_validation_requests").open.any?
    end
  end

  private

  CHECKS.each do |check|
    define_method("#{check}_determined") do
      next unless planning_application.application_type.consistency_checklist.include? check.to_s
      return unless send("#{check}_to_be_determined?")

      errors.add(check, :not_determined)
    end
  end

  REQUEST_TYPES.each do |check, request_type|
    define_method("#{request_type}_requests_closed") do
      return unless send("open_#{request_type}_requests?")

      errors.add(check, "open_#{request_type}_requests".to_sym)
    end

    define_method("open_#{request_type}_requests") do
      memoize(
        "open_#{request_type}_requests",
        planning_application.send("#{request_type}_validation_requests").open
      )
    end
  end
end
