# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def initialize(status:)
      @status = status
    end

    private

    attr_reader :status

    def html_classes
      [
        "govuk-tag",
        colour_class,
        ("app-task-list__task-tag" if task_list?)
      ].compact.join(" ")
    end

    def colour_class
      case status
      when :not_started, :not_checked_yet
        "govuk-tag--grey"
      when :complete
        "govuk-tag--blue"
      when :checked, :granted
        "govuk-tag--green"
      when :updated
        "govuk-tag--yellow"
      when :refused, :removed
        "govuk-tag--red"
      end
    end

    def task_list?
      true
    end
  end
end
