# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def initialize(status:)
      @status = status
    end

    def render?
      status.present?
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
      case status.to_sym
      when :not_started, :new
        "govuk-tag--grey"
      when :in_progress, :awaiting_responses
        "govuk-tag--blue"
      when :checked, :granted, :valid, :completed, :posted, :supportive, :approved
        "govuk-tag--green"
      when :updated, :to_be_reviewed, :submitted, :neutral
        "govuk-tag--yellow"
      when :refused, :removed, :invalid, :technical_failure, :permanent_failure, :rejected, :objection, :failed
        "govuk-tag--red"
      when :printing, :awaiting_response
        "govuk-tag--purple"
      end
    end

    def task_list?
      true
    end
  end
end
