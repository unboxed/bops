# frozen_string_literal: true

module ConsiderationsHelper
  def summary_tag_label(summary_tag)
    return unless summary_tag
    label = t("helpers.summary_tags.#{summary_tag}", default: summary_tag.titleize)
    css_class =
      case summary_tag
      when "complies"
        "govuk-tag govuk-tag--green"
      when "needs_changes"
        "govuk-tag govuk-tag--yellow"
      when "does_not_comply"
        "govuk-tag govuk-tag--red"
      else
        "govuk-tag govuk-tag--grey"
      end

    content_tag(:span, label, class: css_class)
  end
end
