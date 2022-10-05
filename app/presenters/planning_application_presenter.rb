# frozen_string_literal: true

class PlanningApplicationPresenter
  include Presentable

  presents :planning_application

  include StatusPresenter
  include ProposalDetailsPresenter
  include ValidationTasksPresenter
  include AssessmentTasksPresenter

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

  %i[awaiting_determination_at expiry_date outcome_date].each do |date|
    define_method("formatted_#{date}") { send(date).strftime("%e %b") }
  end
end
