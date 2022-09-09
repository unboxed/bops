# frozen_string_literal: true

module PolicyReferencesHelper
  def formatted_policy_refs(policy_refs)
    return if policy_refs.blank?

    refs = policy_refs.map do |ref|
      url = ref.url
      text = ref.text
      link_to_if(url.present?, (url || text), url, class: "govuk-link")
    end

    refs.join(", ").html_safe # rubocop:disable Rails/OutputSafety
  end
end
