# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class SiteVisitsController < AuthenticationController
      before_action :set_planning_application
      before_action :redirect_to_assessment_tasks, unless: :site_visits_feature?
      before_action :set_consultation
      before_action :build_site_visit, only: %i[new create]
      before_action :set_site_visit, only: %i[show]

      def index
        @site_visits = @planning_application.site_visits.by_created_at_desc.includes(:created_by)

        respond_to do |format|
          format.html
        end
      end

      def show
        respond_to do |format|
          format.html
        end
      end

      def new
        respond_to do |format|
          format.html
        end
      end

      def create
        respond_to do |format|
          if @site_visit.update(site_visit_params)
            format.html do
              redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
            end
          else
            format.html { render :new }
          end
        end
      end

      private

      def site_visit_params
        params.require(:site_visit)
          .permit(:decision, :comment, :visited_at, :neighbour_id, :address, documents: [])
          .merge(created_by: current_user, status: "complete")
      end

      def set_consultation
        @consultation = @planning_application.consultation
      end

      def set_site_visit
        @site_visit = @planning_application.site_visits.find(params[:id])
      end

      def build_site_visit
        @site_visit = @planning_application.site_visits.new
      end

      def redirect_to_assessment_tasks
        redirect_to planning_application_assessment_tasks_path(@planning_application)
      end

      def site_visits_feature?
        @planning_application.application_type.site_visits?
      end
    end
  end
end
