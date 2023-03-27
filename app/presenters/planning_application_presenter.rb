# frozen_string_literal: true

class PlanningApplicationPresenter
  include Presentable

  presents :planning_application

  include StatusPresenter
  include ProposalDetailsPresenter
  include ValidationTasksPresenter
  include AssessmentTasksPresenter
  include ActionView::Helpers::SanitizeHelper

  def initialize(template, planning_application)
    @template = template
    @planning_application = planning_application
  end

  def outcome_date
    send("#{status}_at")
  end

  def application_type_name
    I18n.t("application_types.#{application_type}")
  end

  def application_type_abbreviation
    I18n.t("application_types.#{application_type}_abbr", default: application_type_name)
  end

  def application_type_with_status
    status_title = work_status.titlecase
    sanitize(
      "<abbr title=\"#{application_type_name} #{status_title}\">" \
      "#{application_type_abbreviation} #{status_title}</abbr>"
    )
  end

  %i[awaiting_determination_at expiry_date outcome_date].each do |date|
    define_method("formatted_#{date}") { send(date).strftime("%e %b") }
  end
end
