# frozen_string_literal: true

class PlanningApplicationPresenter
  include BopsCore::Presentable

  presents :planning_application

  include BopsCore::StatusPresenter
  include ProposalDetailsPresenter
  include ValidationTasksPresenter
  include AssessmentTasksPresenter
  include ActionView::Helpers::SanitizeHelper

  def initialize(template, planning_application)
    @template = template
    @planning_application = planning_application
  end

  def outcome_date
    send(:"#{status}_at")
  end

  %i[awaiting_determination_at expiry_date outcome_date].each do |date|
    define_method(:"formatted_#{date}") { public_send(date).to_date.to_fs }
  end

  def display_section_55_development
    case @planning_application.section_55_development
    when TrueClass
      "Yes"
    when FalseClass
      "No"
    when NilClass
      "Not specified"
    end
  end
end
