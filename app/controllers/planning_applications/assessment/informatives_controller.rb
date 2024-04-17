# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class InformativesController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_informative_set
      before_action :set_informative

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

      def destroy
        respond_to do |format|
          format.html do
            if @informative.destroy
              redirect_to planning_application_assessment_informatives_path(@planning_application),
                notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @informative.update(informatives_params) && @informative_set.update(informative_set_params)
              redirect_to update_url, notice: t(".success")
            elsif request.referrer.include? "edit"
              render :edit
            else
              render :index
            end
          end
        end
      end

      def complete
        review = @informative_set.current_review || @informative_set.reviews.create!(assessor: Current.user)

        if review.update(status:)
          redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
        else
          render :index
        end
      end

      private

      def set_informative_set
        @informative_set = @planning_application.informative_set
      end

      def set_informative
        @informative = if params[:informative_id]
          @informative_set.informatives.find(params[:informative_id])
        elsif params[:id].to_i > 0
          @informative_set.informatives.find(params[:id])
        else
          @informative_set.informatives.new
        end
      end

      def informatives_params
        params.require(:informative)
          .permit(
            :id, :title, :text, :informative_set_id
          )
      end

      def informative_set_params
        {reviews_attributes: [status:, id: (@informative_set&.current_review&.id if !mark_as_complete?)]}
      end

      def status
        if mark_as_complete?
          if @informative_set.current_review.present? && @informative_set.current_review.status == "to_be_reviewed"
            "updated"
          else
            "complete"
          end
        else
          "in_progress"
        end
      end

      def mark_as_complete?
        params[:action] == "complete"
      end

      def update_url
        if params[:save] == "true"
          planning_application_assessment_tasks_path(@planning_application)
        else
          planning_application_assessment_informatives_path(@planning_application)
        end
      end
    end
  end
end
