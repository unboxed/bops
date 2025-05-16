# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class RequirementsController < BaseController
      include ReturnToReport

      before_action :set_requirements, only: %i[index create]
      before_action :set_requirement, only: %i[update edit destroy]
      before_action :store_return_to_report_path, only: %i[index]

      def index
        @categories = LocalAuthority::Requirement.categories
        @existing_requirements = @planning_application.requirements.pluck(:description)
        @application_type_requirements = ApplicationTypeRequirement.includes(:local_authority_requirement).where(
          local_authority_requirement: {local_authority_id: @planning_application.local_authority.id},
          application_type_id: @planning_application.recommended_application_type_id
        ).pluck(:description)
        respond_to do |format|
          format.html
        end
      end

      def create
        @categories = LocalAuthority::Requirement.categories
        @requirements.where(id: params[:requirement_ids]).find_each do |requirement|
          application_requirement = @planning_application.requirements.new(
            description: requirement.description,
            guidelines: requirement.guidelines,
            url: requirement.url,
            category: requirement.category
          )
          application_requirement.save!
        end
        redirect_to planning_application_assessment_requirements_path(@planning_application), notice: t(".success")

        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        @requirement.update!(planning_application_requirement_params)
        redirect_to planning_application_assessment_requirements_path(@planning_application), notice: t(".success")

        respond_to do |format|
          format.html
        end
      end

      def destroy
        if @requirement.destroy
          redirect_to planning_application_assessment_requirements_path(@planning_application), notice: t(".success")
        else
          redirect_to planning_application_assessment_requirements_path(@planning_application), notice: t(".failure")
        end
        respond_to do |format|
          format.html
        end
      end

      private

      def set_requirements
        @requirements = @planning_application.local_authority.requirements
      end

      def set_requirement
        @requirement = @planning_application.requirements.find(params[:id])
      end

      def planning_application_requirement_params
        params.require(:planning_application_requirement).permit(:url, :guidelines)
      end
    end
  end
end
