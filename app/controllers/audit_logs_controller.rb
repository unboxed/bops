class AuditLogsController < ApplicationController
  def index
    @planning_application = PlanningApplication.find(params[:planning_application_id])
    @audit_logs = @planning_application.own_and_associated_audits
  end
end
