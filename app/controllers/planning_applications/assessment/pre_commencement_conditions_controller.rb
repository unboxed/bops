# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class PreCommencementConditionsController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_condition_set
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
        if send_to_applicant?
          @condition_set.confirm_pending_requests!
        elsif mark_as_complete?
          @condition_set.create_or_update_review!("complete")
        else
          @condition_set.create_or_update_review!("in_progress")
        end

        respond_to do |format|
          format.html do
            redirect_to confirmation_url, notice: t(".#{send_to_applicant? ? "complete" : "save"}.success")
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

      def pre_commencement_condition_params
        params.require(:condition).permit(*pre_commencement_condition_attributes)
          .to_h.merge(reviews_attributes: [status:, id: (@condition_set&.current_review&.id if !mark_as_complete?)])
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

      def send_to_applicant?
        params[:commit] == "Confirm and send to applicant"
      end

      def confirmation_url
        if send_to_applicant?
          planning_application_assessment_pre_commencement_conditions_path(@planning_application)
        else
          planning_application_assessment_tasks_path(@planning_application)
        end
      end

      def status
        if mark_as_complete?
          "complete"
        else
          "in_progress"
        end
      end
    end
  end
end
