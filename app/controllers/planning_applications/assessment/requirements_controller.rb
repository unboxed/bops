# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class RequirementsController < BaseController
      before_action :set_requirement, only: %i[edit update]

      def index
        @requirements = @planning_application.local_authority.requirements
        @categories = LocalAuthority::Requirement.categories
        respond_to do |format|
          format.html
        end
      end

      def create
        respond_to do |format|
          format.html
        end
        # choose requirements selected, iterate over (each?)
        # @planning_application.planning_application_requirement.new(params)
      end

      # def edit
      #   respond_to do |format|
      #     format.html
      #   end
      # end

      def update
        respond_to do |format|
          format.html
        end
      end

      private

      def set_requirement
        @requirement = @planning_application.local_authority.requirements.find(params[:id])
      end

      # permitted params for planning_application_requirement
    end
  end
end
