# frozen_string_literal: true

class EnforcementPresenter
  def initialize(enforcement)
    @enforcement = enforcement
  end

  def status_tag_colour
    "orange"
  end

  def status_tag
    classes = ["govuk-tag govuk-tag--#{status_tag_colour}"]

    tag.span class: classes do
      "unknown"
      # status' to be added later
    end
  end

  def days_status_tag
    classes = ["govuk-tag", "govuk-tag--orange"]

    tag.span class: classes.join(" ") do
      I18n.t("enforcement.days_from", count: days_from)
    end
  end
end
