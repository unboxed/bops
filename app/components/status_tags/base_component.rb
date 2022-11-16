# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def initialize(status:)
      @status = status
    end

    private

    attr_reader :status

    def colour_class
      case status
      when :not_started, :not_checked_yet
        "govuk-tag--grey"
      when :complete
        "govuk-tag--blue"
      when :checked
        "govuk-tag--green"
      when :updated
        "govuk-tag--yellow"
      end
    end

    def task_list?
      true
    end
  end
end
