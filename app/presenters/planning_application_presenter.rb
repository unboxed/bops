# frozen_string_literal: true

class PlanningApplicationPresenter
  include Rails.application.routes.url_helpers

  attr_reader :template, :planning_application

  delegate :tag, :concat, :link_to, :truncate, :link_to_if, to: :template
  delegate :to_param, to: :planning_application

  include StatusPresenter
  include ProposalDetailsPresenter
  include ValidationTasksPresenter
  include AssessmentTasksPresenter

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
