# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class PreCommencementConditionsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_condition_set
      before_action :set_conditions, only: [:index, :create]
      before_action :set_condition

      def index
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
        @condition.attributes = pre_commencement_condition_params

        respond_to do |format|
          format.html do
            if @condition.save
              redirect_to planning_application_assessment_pre_commencement_conditions_path(@planning_application), notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @condition.update(pre_commencement_condition_params)
              redirect_to planning_application_assessment_pre_commencement_conditions_path(@planning_application), notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def confirm
        @condition_set.confirm_pending_requests!

        respond_to do |format|
          format.html do
            redirect_to planning_application_assessment_pre_commencement_conditions_path(@planning_application), notice: t(".success")
          end
        end
      rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
        redirect_to planning_application_assessment_pre_commencement_conditions_path(@planning_application),
          alert: "Couldn't confirm requests with error: #{e.message}. Please contact support."
      end

      def destroy
        respond_to do |format|
          format.html do
            if @condition.destroy
              redirect_to planning_application_assessment_pre_commencement_conditions_path(@planning_application), notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      private

      def set_condition_set
        @condition_set = @planning_application.pre_commencement_condition_set
      end

      def set_conditions
        @conditions = @condition_set.conditions
      end

      def pre_commencement_condition_params
        params.require(:condition).permit(*pre_commencement_condition_attributes)
      end

      def set_condition
        @condition = if params[:id]
          @condition_set.conditions.find(params[:id])
        else
          @condition_set.conditions.build
        end
      end

      def pre_commencement_condition_attributes
        %i[title text reason]
      end
    end
  end
end