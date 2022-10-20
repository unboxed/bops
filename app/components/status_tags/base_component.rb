# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def colour_class
      case status
      when :not_started, :not_checked_yet
        "govuk-tag--grey"
      when :complete
        "govuk-tag--blue"
      when :checked
        "govuk-tag--green"
      end
    end
  end
end
