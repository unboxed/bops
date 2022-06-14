# frozen_string_literal: true

module ProposalDetailsPresenter
  extend ActiveSupport::Concern

  included do
    def proposal_detail_item(proposal)
      tag.p(class: "govuk-body") do
        concat proposal_question(proposal)
        concat proposal_responses(proposal)
        concat proposal_metadata(proposal)
      end
    end

    def fee_related_proposal_details
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name&.match(/(_|\b)fee(_|\b)/i)
      end
    end

    def grouped_proposal_details
      @grouped_proposal_details ||= proposal_detail_groups.map do |group|
        [group, proposal_details_for_group(group)]
      end
    end

    private

    def proposal_details_for_group(group)
      proposal_details.select do |proposal_detail|
        proposal_detail.metadata&.portal_name == group
      end
    end

    def proposal_detail_groups
      proposal_details.map do |proposal_detail|
        proposal_detail.metadata&.portal_name
      end.uniq
    end

    def proposal_question(proposal)
      tag.p(class: "govuk-body") do
        tag.strong(proposal.question)
      end
    end

    def proposal_responses(proposal)
      tag.p(class: "govuk-body") do
        proposal.responses.map(&:value).compact.join(", ")
      end
    end

    def proposal_metadata(proposal)
      metadata = proposal.metadata

      return if metadata.nil?

      tag.div do
        concat proposal_notes(proposal)
        concat proposal_auto_answered(proposal)
        concat proposal_policy_refs(proposal)
      end
    end

    def proposal_notes(proposal)
      notes = proposal.metadata.notes

      tag.p(tag.em(notes)) if notes.present?
    end

    def proposal_auto_answered(proposal)
      auto_answered = proposal.metadata.auto_answered

      tag.p(tag.em("Auto-answered by RIPA")) if auto_answered.present?
    end

    def proposal_policy_refs(proposal)
      refs = proposal.metadata&.policy_refs

      return if refs.blank?

      refs.map do |ref|
        if ref.url.present?
          link_to(ref.url, ref.url, class: "govuk-link")
        else
          ref.text
        end
      end.join
    end
  end
end
