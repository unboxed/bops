# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def initialize(status:, task_list: true)
      @status = status
      @task_list = task_list
    end

    def render?
      status.present?
    end

    private

    attr_reader :status, :task_list

    def html_classes
      [
        "govuk-tag",
        colour_class,
        ("app-task-list__task-tag" if task_list?)
      ].compact.join(" ")
    end

    def colour_class
      case status.to_sym
      when :not_started, :new, :review_not_started, :not_consulted
        "govuk-tag--blue"
      when :in_progress, :sending
        "govuk-tag--light-blue"
      when :updated, :to_be_reviewed, :submitted, :neutral, :amendments_needed
        "govuk-tag--yellow"
      when :refused, :removed, :invalid, :technical_failure, :permanent_failure, :rejected, :objection, :failed, :refused_legal_agreement
        "govuk-tag--red"
      when :printing
        "govuk-tag--purple"
      end
    end

    def task_list?
      task_list
    end
  end
end
