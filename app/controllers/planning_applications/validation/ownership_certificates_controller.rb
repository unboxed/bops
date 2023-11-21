# frozen_string_literal: true

module PlanningApplications
  module Validation
    class OwnershipCertificatesController < ApplicationController
      before_action :set_planning_application

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        if @planning_application.update(planning_application_params)
          if @planning_application.valid_ownership_certificate?
            redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(".success")
          else
            redirect_to new_planning_application_validation_validation_request_path(@planning_application,
              type: "ownership_certificate")
          end
        else
          render :edit
        end
      end

      private

      def planning_application_params
        params.require(:planning_application).permit(:valid_ownership_certificate)
      end
    end
  end
end
