# frozen_string_literal: true

class PlanningApplicationPresenter
  attr_reader :template, :planning_application

  delegate :tag, to: :template
  delegate :to_param, to: :planning_application

  STATUS_COLOURS = {
    invalidated: "yellow",
    not_started: "grey",
    in_assessment: "turquoise",
    awaiting_determination: "purple",
    awaiting_correction: "green"
  }.freeze

  def initialize(template, planning_application)
    @template = template
    @planning_application = planning_application
  end

  def method_missing(symbol, *args)
    if planning_application.respond_to?(symbol)
      planning_application.send(symbol, *args)
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_private = false)
    super || planning_application.respond_to?(symbol)
  end

  concerning :Status do
    def status_tag
      classes = ["govuk-tag govuk-tag--#{status_tag_colour}"]

      tag.span class: classes do
        status
      end
    end

    def remaining_days_status_tag
      classes = ["govuk-tag govuk-tag--#{status_date_tag_colour}"]

      tag.span class: classes do
        I18n.t("planning_applications.days_left", count: planning_application.days_left)
      end
    end

    def type
      I18n.t(planning_application.application_type, scope: "application_types")
    end

    def status
      planning_application.status.humanize
    end

    def work_status
      planning_application.work_status.humanize
    end

    def type_and_work_status
      "#{type} (#{work_status})"
    end
  end

  concerning :Address do
    def full_address
      "#{address_1}, #{town}, #{postcode}"
    end
  end

  private

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
