# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class LocalPolicyAreasController < AuthenticationController
      before_action :set_planning_application
      before_action :set_local_policy, only: %i[show edit update new]
      before_action :set_local_policy_area, only: %i[edit show]

      def show
        set_local_policy_area
      end

      def new
        @local_policy_area = LocalPolicyArea.new
      end

      def edit
        set_local_policy_area
      end

      def destroy
        @local_policy_area = LocalPolicyArea.find(params[:id])
        @local_policy_area.destroy!

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
          render :new
        end
      end

      def update
        set_local_policy_area
        if @local_policy_area.update(local_policy_params)
          redirect_to edit_planning_application_assessment_local_policy_path(@planning_application, @planning_application.local_policy),
            notice: I18n.t("local_policies.successfully_updated")
        else
          render :edit
        end
      end

      private

      def set_local_policy
        @local_policy = @planning_application.local_policy.presence || LocalPolicy.create!(planning_application_id: @planning_application.id)
      end

      def set_local_policy_area
        @local_policy_area = LocalPolicyArea.find(params[:id])
      end

      def policy_params
        params.permit([:area, :id, :policies, :policy, :assessment, :guidance])
      end

      def local_policy_params
        params.require(:local_policy_area).permit([:area, :id, :policies, :policy, :assessment, :guidance, :local_policy_id])
      end
    end
  end
end
