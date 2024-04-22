# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def initialize(status:, task_list: true, float: "right")
      @status = status
      @task_list = task_list
      @float = float
    end

    def render?
      status.present?
    end

    def float
      "float-#{@float}"
    end

    private

    attr_reader :status, :task_list

    def html_classes
      [
        "govuk-tag",
        colour_class,
        ("app-task-list__task-tag" if task_list?),
        float
      ].compact.join(" ")
    end

    def colour_class
      case status.to_sym
      when :not_started, :new, :review_not_started, :not_consulted
        "govuk-tag--grey"
      when :in_progress, :awaiting_responses, :review_complete, :sending
        "govuk-tag--blue"
      when :checked, :granted, :valid, :completed, :posted, :supportive, :approved, :auto_approved, :granted_legal_agreement, :constraint_added
        "govuk-tag--green"
      when :updated, :to_be_reviewed, :submitted, :neutral, :amendments_needed
        "govuk-tag--yellow"
      when :refused, :removed, :invalid, :technical_failure, :permanent_failure, :rejected, :objection, :failed, :refused_legal_agreement, :constraint_removed
        "govuk-tag--red"
      when :printing, :awaiting_response
        "govuk-tag--purple"
      end
    end

    def task_list?
      task_list
    end
  end
end
