# frozen_string_literal: true

class ProposalDetail
  attr_reader :question
  attr_accessor :index

  def initialize(attributes, index)
    @question = attributes.fetch("question", nil)
    @responses = attributes.fetch("responses", [])
    @metadata = attributes.fetch("metadata", {})
    @index = index
  end

  def auto_answered?
    metadata.fetch("auto_answered", nil).present?
  end

  def flags
    responses.filter_map { |hash| hash.dig("metadata", "flags") }.flatten
  end

  def notes
    metadata.fetch("notes", nil)
  end

  def policy_refs
    metadata["policy_refs"] || []
  end

  def section_name
    metadata.fetch("section_name", nil)
  end

  def portal_name
    metadata.fetch("portal_name", nil)
  end

  def response_values
    responses.pluck("value").compact
  end

  private

  attr_reader :responses, :metadata
end
