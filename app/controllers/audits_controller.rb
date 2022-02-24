# frozen_string_literal: true

class AuditsController < AuthenticationController
  before_action :set_planning_application

  def index
    @audits = @planning_application.audits.with_user_and_api_user
  end
end
