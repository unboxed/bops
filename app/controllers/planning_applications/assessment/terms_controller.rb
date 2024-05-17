# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TermsController < BaseController
      before_action :set_heads_of_term
      before_action :set_term

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
        @term.attributes = term_params

        respond_to do |format|
          format.html do
            if @term.save
              redirect_to planning_application_assessment_terms_path(@planning_application), notice: t(".success")
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
              redirect_to planning_application_assessment_terms_path(@planning_application), notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def confirm
        @heads_of_term.confirm_pending_requests!

        respond_to do |format|
          format.html do
            redirect_to planning_application_assessment_terms_path(@planning_application), notice: t(".success")
          end
        end
      rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
        redirect_to planning_application_assessment_terms_path(@planning_application),
          alert: "Couldn't confirm requests with error: #{e.message}. Please contact support."
      end

      def destroy
        respond_to do |format|
          format.html do
            if @term.destroy
              redirect_to planning_application_assessment_terms_path(@planning_application), notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      private

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
    end
  end
end
