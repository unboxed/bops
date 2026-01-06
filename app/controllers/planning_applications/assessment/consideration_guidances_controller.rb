# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConsiderationGuidancesController < BaseController
      before_action :set_consideration_set
      before_action :set_considerations
      before_action :set_review
      before_action :build_consideration, only: [:index, :create]
      before_action :set_consultee_responses, only: [:index, :edit]
      before_action :set_consideration, only: [:destroy, :edit, :update]

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
        @consideration.submitted_by = current_user

        respond_to do |format|
          format.html do
            if @consideration.update(consideration_params, :advice)
              redirect_to return_path, notice: t(".success")
            else
              set_consultee_responses
              render :index
            end
          end
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @consideration.update(consideration_params, :advice)
              redirect_to return_path, notice: t(".success")
            else
              set_consultee_responses
              render :edit
            end
          end
        end
      end

      def destroy
        respond_to do |format|
          format.html do
            if @consideration.destroy
              redirect_to return_path, notice: t(".success")
            else
              set_consultee_responses
              render :index
            end
          end
        end
      end

      private

      def set_consultee_responses
        @consultee_responses = @planning_application.consultation.consultee_responses
      end

      def set_consideration_set
        @consideration_set = @planning_application.consideration_set
      end

      def set_considerations
        @considerations = @consideration_set.considerations.select(&:persisted?)
      end

      def set_review
        @review = @consideration_set.current_review
      end

      def build_consideration
        @consideration = @consideration_set.considerations.new(draft: true)
      end

      def set_consideration
        @consideration = @consideration_set.considerations.find_by_id(consideration_id)
      end

      def consideration_id
        Integer(params[:id])
      end

      def consideration_params
        params.require(:consideration).permit(
          :policy_area, :draft, :proposal, :summary_tag, :advice, policy_references_attributes: %i[code description url]
        )
      end

      def return_path
        params[:return_to].presence || planning_application_assessment_consideration_guidances_path(@planning_application)
      end
    end
  end
end
