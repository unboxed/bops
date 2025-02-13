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

  def all_valid_documents?
    documents.count == documents.validated.count
  end

  def all_null_documents?
    documents.count == documents.where(validated: nil).count
  end

  %i[awaiting_determination_at expiry_date outcome_date].each do |date|
    define_method(:"formatted_#{date}") { send(date).to_date.to_fs(:day_month_only) }
  end
end
