# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class ResponsesController < AuthenticationController
      before_action :set_planning_application
      before_action :redirect_to_application_page, unless: :public_or_preapp?

      before_action :set_consultation
      before_action :set_consultees, only: %i[index]

      def index
        respond_to do |format|
          format.html
        end
      end

      private

      def set_consultees
        @consultees = @consultation.consultees
      end

      def redirect_to_application_page
        redirect_to make_public_planning_application_path(@planning_application), alert: t(".make_public")
      end

      def public_or_preapp?
        @planning_application.make_public? || @planning_application.pre_application?
      end
    end
  end
end
