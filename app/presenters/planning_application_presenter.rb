# frozen_string_literal: true

class PlanningApplicationPresenter
  include Rails.application.routes.url_helpers

  attr_reader :template, :planning_application

  delegate :tag, :concat, :link_to, :truncate, to: :template
  delegate :to_param, to: :planning_application

  include StatusPresenter
  include ProposalDetailsPresenter
  include ValidationTasksPresenter

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
end
