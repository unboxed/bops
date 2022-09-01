# frozen_string_literal: true

module PolicyReferencesHelper
  def class_for_policy_class_status(status)
    classes = %w[govuk-tag app-task-list__task-tag]

    colour = case status
             when "does not comply"
               "red"
             when "complies"
               "green"
             end

    classes.append "govuk-tag--#{colour}" if colour.present?

    classes.join(" ")
  end

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
