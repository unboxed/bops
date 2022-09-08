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

  def policies_summary(policies)
    if policies.to_be_determined.any?
      t(".to_be_determined")
    elsif policies.does_not_comply.any?
      t(".does_not_comply")
    else
      t(".complies")
    end
  end
end
