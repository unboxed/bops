# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TermsController < BaseController
      before_action :redirect_to_assessment_tasks, unless: :heads_of_terms_enabled?
      before_action :set_heads_of_term
      before_action :set_term

      def index
        respond_to do |format|
          format.html
        end
      end

      def edit
        @show_sidebar = if @planning_application.pre_application? && Rails.configuration.use_new_sidebar_layout
          @planning_application.case_record.find_task_by_path!("check-and-assess")
        end

        respond_to do |format|
          format.html
        end
      end

      def create
        @show_sidebar = if @planning_application.pre_application? && Rails.configuration.use_new_sidebar_layout
          @planning_application.case_record.find_task_by_path!("check-and-assess")
        end

        @term.attributes = term_params

        respond_to do |format|
          format.html do
            if @term.save
              redirect_to redirect_path, notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @term.update(term_params)
              redirect_to redirect_path, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def confirm
        @heads_of_term.confirm_pending_requests! unless @planning_application.pre_application?

        respond_to do |format|
          format.html do
            if @heads_of_term.current_review.update(status: :complete)
              redirect_to planning_application_assessment_tasks_path(@planning_application), notice: created_notice
            else
              render :index
            end
          end
        end
      rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
        redirect_to redirect_path, alert: "Couldn't confirm requests with error: #{e.message}. Please contact support."
      end

      def destroy
        respond_to do |format|
          format.html do
            if @term.destroy
              redirect_to redirect_path, notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      private

      def redirect_to_assessment_tasks
        redirect_to planning_application_assessment_tasks_path(@planning_application)
      end

      def redirect_path
        params[:redirect_to].presence || planning_application_assessment_terms_path(@planning_application)
      end

      def heads_of_terms_enabled?
        @planning_application.heads_of_terms?
      end

      def set_heads_of_term
        @heads_of_term = @planning_application.heads_of_term
      end

      def term_params
        params.require(:term).permit(*term_attributes)
      end

      def set_term
        @term = if params[:id]
          @heads_of_term.terms.find(params[:id])
        else
          @heads_of_term.terms.build
        end
      end

      def term_attributes
        %i[title text]
      end

      def created_notice
        if @planning_application.pre_application?
          t("planning_applications.assessment.terms.confirm.preapp_success")
        else
          t("planning_applications.assessment.terms.confirm.success")
        end
      end
    end
  end
end
