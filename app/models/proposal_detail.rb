# frozen_string_literal: true

class ProposalDetail
  attr_reader :question
  attr_accessor :index

  def initialize(attributes, index)
    @question = attributes["question"]
    @responses = attributes.fetch("responses", [])
    @metadata = attributes.fetch("metadata", {})
    @index = index
  end

  def auto_answered?
    metadata["auto_answered"].present?
  end

  def flags
    responses.filter_map { |hash| hash.dig("metadata", "flags") }.flatten
  end

  def notes
    metadata["notes"]
  end

  def policy_refs
    metadata["policy_refs"] || []
  end

  def section_name
    metadata["section_name"]
  end

  def portal_name
    metadata["portal_name"]
  end

  def response_values
    responses.pluck("value").compact
  end

  private

  attr_reader :responses, :metadata
end
