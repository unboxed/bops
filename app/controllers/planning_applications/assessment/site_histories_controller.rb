# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class SiteHistoriesController < BaseController
      before_action :set_site_histories
      before_action :set_site_history, except: %i[confirm]

      def index
        if @planning_application.planning_history_enabled?
          @site_histories += Apis::Paapi::Query.new.fetch(@planning_application.uprn)
        end

        respond_to do |format|
          format.html
        end
      end

      def confirm
        @planning_application.update!(site_history_checked: true)

        respond_to do |format|
          format.html do
            redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
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
              redirect_to planning_application_assessment_site_histories_path(@planning_application), notice: t(".success")
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
              redirect_to planning_application_assessment_site_histories_path(@planning_application), notice: t(".success")
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
              redirect_to planning_application_assessment_site_histories_path(@planning_application), notice: t(".success")
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
        params.require(:site_history).permit(:application_number, :description, :decision, :date)
      end
    end
  end
end