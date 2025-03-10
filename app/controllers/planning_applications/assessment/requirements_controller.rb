# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class RequirementsController < BaseController
      before_action :set_requirements, only: %i[index create]

      def index
        @categories = LocalAuthority::Requirement.categories
        @existing_requirements = @planning_application.requirements.pluck(:description)
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

      private

      def set_requirements
        @requirements = @planning_application.local_authority.requirements
      end
    end
  end
end
