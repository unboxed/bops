# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class LocalPolicyAreasController < AuthenticationController
      before_action :set_planning_application
      before_action :set_local_policy, only: %i[show edit update new destroy]
      before_action :set_local_policy_area, only: %i[edit show]

      def show
      end

      def new
        @local_policy_area = @local_policy.local_policy_areas.new
      end

      def edit
      end

      def destroy
        @local_policy.local_policy_areas.destroy(params[:id])

        redirect_to new_planning_application_assessment_local_policy_path(@planning_application)
      end

      def create
        set_local_policy
        @local_policy_area = LocalPolicyArea.new(local_policy_params.except(:policy))

        if @local_policy_area.save
          if @planning_application.local_policy.present?
            redirect_to edit_planning_application_assessment_local_policy_path(@planning_application, @planning_application.local_policy)
          else
            redirect_to new_planning_application_assessment_local_policy_path(@planning_application)
          end
        else
          respond_to do |format|
            format.html { render :new }
          end
        end
      end

      def update
        set_local_policy_area
        if @local_policy_area.update(local_policy_params)
          redirect_to edit_planning_application_assessment_local_policy_path(@planning_application, @planning_application.local_policy),
            notice: I18n.t("local_policies.successfully_updated")
        else
          respond_to do |format|
            format.html { render :new }
          end
        end
      end

      private

      def set_local_policy
        @local_policy = @planning_application.local_policy || @planning_application.create_local_policy!
      end

      def set_local_policy_area
        @local_policy_area = @local_policy.local_policy_areas.find(params[:id])
      end

      def local_policy_params
        params.require(:local_policy_area).permit([:area, :id, :policies, :policy, :assessment, :guidance, :local_policy_id])
      end
    end
  end
end
