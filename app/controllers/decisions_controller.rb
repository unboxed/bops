# frozen_string_literal: true

class DecisionsController < AuthenticationController
  before_action :set_planning_application
  before_action :set_application_type
  before_action :set_decision_notice

  def show
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  private

  def set_application_type
    @application_type = @planning_application.application_type
  end

  def set_decision_notice
    @decision_notice = @application_type.decision_notice
  end
end
