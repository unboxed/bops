# frozen_string_literal: true

module ProposalDetails
  class PolicyRefsComponent < ViewComponent::Base
    include ProposalDetailable

    def initialize(policy_refs:)
      @policy_refs = policy_refs
    end

    def render?
      policy_refs.any?
    end

    private

    attr_reader :policy_refs
  end
end
