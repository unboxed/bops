# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class RequirementsController < BaseController
      include ReturnToReport

      before_action :set_local_authority_requirements, only: %i[index create]
      before_action :set_application_type, only: %i[index create]
      before_action :set_requirements, only: %i[index create]
      before_action :set_new_requirements, only: %i[create]
      before_action :set_requirement, only: %i[update edit destroy]
      before_action :store_return_to_report_path, only: %i[index]

      def index
        respond_to do |format|
          format.html
        end
      end

      def create
        respond_to do |format|
          if @planning_application.add_requirements(@new_requirements)
            format.html do
              redirect_to redirect_path, notice: t(".success")
            end
          else
            format.html do
              redirect_to redirect_path, notice: t(".failure")
            end
          end
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @requirement.update(requirement_params)
            format.html do
              redirect_to redirect_path, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      def destroy
        respond_to do |format|
          if @requirement.destroy
            format.html do
              redirect_to planning_application_assessment_requirements_path(@planning_application), notice: t(".success")
            end
          else
            format.html do
              redirect_to planning_application_assessment_requirements_path(@planning_application), alert: t(".failure")
            end
          end
        end
      end

      private

      def set_local_authority_requirements
        @local_authority_requirements = current_local_authority.requirements
      end

      def set_application_type
        @application_type = @planning_application.recommended_application_type
      end

      def set_requirements
        @requirements = @planning_application.requirements
      end

      def set_requirement
        @requirement = @planning_application.requirements.find(params[:id])
      end

      def requirement_params
        params.require(:requirement).permit(:url, :guidelines)
      end

      def new_requirement_ids
        params.fetch(:new_requirement_ids, []).compact_blank
      end

      def set_new_requirements
        @new_requirements = current_local_authority.requirements.find(new_requirement_ids)

        if @new_requirements.empty?
          redirect_to redirect_path, alert: t(".missing")
        end
      end

      def redirect_path
        params[:redirect_to].presence || planning_application_assessment_requirements_path(@planning_application)
      end
    end
  end
end
