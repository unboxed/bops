# frozen_string_literal: true

module PlanningApplications
  module Appeals
    class DecisionsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_appeal

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @appeal.update(appeal_params, :determine)
            @appeal.determine! unless @appeal.determined?
            format.html do
              redirect_to planning_application_appeal_path(@planning_application), notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def set_appeal
        @appeal = @planning_application.appeal

        return if @appeal&.determined? || @appeal&.may_determine?

        redirect_to planning_application_path(@planning_application), alert: t(".not_found")
      end

      def appeal_params
        params.require(:appeal).permit(:reason, :decision, :determined_at, documents: [])
      end
    end
  end
end
