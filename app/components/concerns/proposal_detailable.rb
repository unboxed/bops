# frozen_string_literal: true

module ProposalDetailable
  extend ActiveSupport::Concern

  included do
    def formatted_policy_refs
      return if policy_refs.none?

      policy_refs.map do |policy_ref|
        formatted_policy_ref(policy_ref)
      end.join(", ").html_safe # rubocop:disable Rails/OutputSafety
    end

    def formatted_policy_ref(policy_ref)
      url = policy_ref["url"]
      text = policy_ref["text"]
      link_to_if(url.present?, (url || text), url, class: "govuk-link")
    end
  end
end
