# frozen_string_literal: true

module PlanningApplications
  class AssignUsersController < AuthenticationController
    include ReturnToReport

    before_action :set_planning_application
    before_action :set_users
    before_action :store_return_to_report_path, only: :index

    def index
      respond_to do |format|
        format.html
      end
    end

    def update
      user = @users.find_by(id: params[:user_id])

      @planning_application.assign!(user)

      respond_to do |format|
        format.html { redirect_to report_path_or(@planning_application) }
      end
    rescue ActiveRecord::ActiveRecordError => e
      redirect_to planning_application_assign_users_path(@planning_application),
        alert: "Couldn't assign user with error: #{e.message}. Please contact support."
    end

    def set_users
      @users = current_local_authority.users.non_administrator
    end
  end
end
