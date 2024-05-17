# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class LocalPolicyAreasController < BaseController
      before_action :set_local_policy
      before_action :set_local_policy_area, only: %i[edit show update destroy]

      def show
        respond_to do |format|
          format.html
        end
      end

      def new
        @local_policy_area = @local_policy.local_policy_areas.new
        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def destroy
        @local_policy_area.destroy!

        redirect_to new_planning_application_assessment_local_policy_path(@planning_application)
      end

      def create
        @local_policy_area = @local_policy.local_policy_areas.new(local_policy_params.except(:policy))

        if @local_policy_area.save
          redirect_to edit_planning_application_assessment_local_policy_path(@planning_application, @planning_application.local_policy)
        else
          respond_to do |format|
            format.html { render :new }
          end
        end
      end

      def update
        if @local_policy_area.update(local_policy_params)
          @local_policy.create_review! if @local_policy.current_review&.review_complete?

          redirect_to redirect_path, notice: t(".successfully_updated")
        else
          respond_to do |format|
            format.html { render :new }
          end
        end
      end

      private

      def redirect_path
        if current_user.reviewer?
          edit_planning_application_review_local_policy_path(@planning_application, @planning_application.local_policy)
        else
          edit_planning_application_assessment_local_policy_path(@planning_application, @planning_application.local_policy)
        end
      end

      def set_local_policy
        @local_policy = @planning_application.local_policy || @planning_application.create_local_policy!
      end

      def set_local_policy_area
        @local_policy_area = @local_policy.local_policy_areas.find(params[:id])
      end

      def local_policy_params
        params.require(:local_policy_area).permit([:area, :policies, :assessment, :guidance, :conclusion])
      end
    end
  end
end
