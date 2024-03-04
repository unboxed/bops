# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class InformativesController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_informatives, only: %i[index]
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
                notice: I18n.t("informatives.destroy.success")
            else
              render :index
            end
          end
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @informative.update(informatives_params)
              redirect_to planning_application_assessment_informatives_path(@planning_application),
                notice: I18n.t("informatives.update.success")
            else
              if request.referrer.include? "edit"
                render :edit
              else
                set_informatives
                render :index
              end
            end
          end
        end
      end

      private

      def set_informatives
        @informatives = @planning_application.informatives.select(&:persisted?)
      end

      def set_informative
        if params[:informative_id]
          @informative = @planning_application.informatives.find(params[:informative_id])
        elsif params[:id].to_i > 0
          @informative = @planning_application.informatives.find(params[:id])
        else
          @informative = @planning_application.informatives.new
        end
      end

      def informatives_params
        params.require(:informative)
          .permit(
            :id, :title, :text
          )
          # .to_h.merge(reviews_attributes: [status:, id: (@condition_set&.current_review&.id if !mark_as_complete?)])
      end

      def status
        if mark_as_complete?
          if @condition_set.current_review.present? && @condition_set.current_review.status == "to_be_reviewed"
            "updated"
          else
            "complete"
          end
        else
          "in_progress"
        end
      end
    end
  end
end
