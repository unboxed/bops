# frozen_string_literal: true

module StatusPresenter
  extend ActiveSupport::Concern

  STATUS_COLOURS = {
    invalidated: "yellow",
    not_started: "grey",
    in_assessment: "turquoise",
    awaiting_determination: "purple",
    awaiting_correction: "yellow"
  }.freeze

  included do
    def status_tag
      classes = ["govuk-tag govuk-tag--#{status_tag_colour}"]

      tag.span class: classes do
        if determined?
          decision.humanize
        elsif awaiting_correction?
          "To be reviewed"
        else
          aasm.human_state.humanize
        end
      end
    end

    def remaining_days_status_tag
      classes = ["govuk-tag govuk-tag--#{status_date_tag_colour}"]

      tag.span class: classes do
        if expiry_date.past?
          I18n.t("planning_applications.overdue", count: days_overdue)
        else
          I18n.t("planning_applications.days_left", count: days_left)
        end
      end
    end

    alias_method :outcome, :status_tag

    def next_relevant_date_tag
      tag.strong(next_date_label) + tag.span(next_date.to_fs)
    end

    def next_date_label
      if in_progress?
        "Expiry date: "
      elsif determined?
        "#{decision.humanize} at: "
      else
        "#{status.humanize} at: "
      end
    end

    def next_date
      if in_progress?
        expiry_date
      elsif determined?
        determination_date.to_date
      else
        send("#{status}_at")
      end
    end
  end

  def validation_status
    if validation_complete?
      :complete
    elsif validation_requests.any? || any_validation_tasks_complete?
      :in_progress
    else
      :not_started
    end
  end

  private

  def any_validation_tasks_complete?
    valid_fee? ||
      valid_red_line_boundary? ||
      constraints_checked? ||
      documents.any?(&:validated?) ||
      documents_missing == false
  end

  def status_tag_colour
    if planning_application.determined?
      planning_application.granted? ? "green" : "red"
    else
      colour = STATUS_COLOURS[planning_application.status.to_sym]

      colour || "grey"
    end
  end

  def status_date_tag_colour
    return "grey" if @planning_application.determined?

    number = planning_application.days_left

    if number > 11
      "green"
    elsif number.between?(6, 10)
      "yellow"
    else
      "red"
    end
  end
end
