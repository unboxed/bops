# frozen_string_literal: true

class AuditsController < AuthenticationController
  before_action :set_planning_application

  def index
    @audits = Audit.where(planning_application_id: params[:planning_application_id])
  end

private

  def set_planning_application
    @planning_application = current_local_authority.planning_applications.find(params[:planning_application_id])
  end
end
