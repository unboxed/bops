# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class SiteHistoriesController < BaseController
      include ReturnToReport

      before_action :set_site_histories
      before_action :set_site_history, except: %i[confirm]
      before_action :store_return_to_report_path, only: %i[index edit update destroy]

      def index
        respond_to do |format|
          format.html
        end
      end

      def confirm
        @planning_application.update!(site_history_checked: true)

        respond_to do |format|
          format.html do
            redirect_to redirect_path, notice: t(".success")
          end
        end
      end

      def new
        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def create
        @site_history.assign_attributes(planning_history_params)

        respond_to do |format|
          format.html do
            if @site_history.save
              redirect_to submission_redirect_path, notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      def destroy
        respond_to do |format|
          format.html do
            if @site_history.destroy
              redirect_to submission_redirect_path, notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @site_history.update(planning_history_params)
              redirect_to submission_redirect_path, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def set_site_histories
        @site_histories = @planning_application.site_histories.all
      end

      def set_site_history
        @site_history = if params[:id]
          @planning_application.site_histories.find(params[:id])
        else
          @planning_application.site_histories.new
        end
      end

      def planning_history_params
        params.require(:site_history).permit(:reference, :description, :decision, :other_decision, :date, :comment, :address)
      end

      def redirect_path
        report_path_or(planning_application_assessment_tasks_path(@planning_application))
      end

      def submission_redirect_path
        params[:return_to].presence || planning_application_assessment_site_histories_path(@planning_application)
      end
    end
  end
end
