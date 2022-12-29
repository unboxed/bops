# frozen_string_literal: true

module ProposalDetails
  class SummaryComponent < ViewComponent::Base
    include ProposalDetailable

    def initialize(proposal_detail:)
      @proposal_detail = proposal_detail
    end

    private

    attr_reader :proposal_detail

    delegate(
      :index,
      :question,
      :policy_refs,
      :response_values,
      :auto_answered?,
      :notes,
      to: :proposal_detail
    )

    def show_metadata?
      policy_refs.any? || notes.present? || auto_answered?
    end
  end
end
