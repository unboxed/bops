# frozen_string_literal: true

class AuditsController < AuthenticationController
  before_action :set_planning_application

  def index
    @audits = @planning_application.audits
  end
end
