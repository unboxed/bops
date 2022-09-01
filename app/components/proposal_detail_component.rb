# frozen_string_literal: true

class ProposalDetailComponent < ViewComponent::Base
  def initialize(proposal_detail:)
    @proposal_detail = proposal_detail
  end

  private

  attr_reader :proposal_detail

  delegate :number, :question, :responses, :metadata, to: :proposal_detail

  delegate(
    :auto_answered,
    :policy_refs,
    :notes,
    to: :metadata,
    allow_nil: true
  )

  def auto_answered?
    auto_answered.present?
  end

  def formatted_policy_refs
    return if policy_refs.blank?

    refs = policy_refs.map do |ref|
      url = ref.url
      text = ref.text
      link_to_if(url.present?, (url || text), url, class: "govuk-link")
    end

    refs.join(", ").html_safe # rubocop:disable Rails/OutputSafety
  end
end
