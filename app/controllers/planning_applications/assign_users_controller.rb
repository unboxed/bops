# frozen_string_literal: true

module PlanningApplications
  class AssignUsersController < AuthenticationController
    before_action :set_planning_application
    before_action :set_users

    def index
      respond_to do |format|
        format.html
      end
    end

    def update
      user = @users.find_by(id: params[:user_id])

      @planning_application.assign!(user)

      respond_to do |format|
        format.html { redirect_to @planning_application }
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
