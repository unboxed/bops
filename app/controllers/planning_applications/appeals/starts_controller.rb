# frozen_string_literal: true

module PlanningApplications
  module Appeals
    class StartsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_appeal

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @appeal.update(appeal_params, :start)
            @appeal.start!
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

        unless @appeal&.may_start?
          redirect_to planning_application_path(@planning_application), alert: t(".not_found")
        end
      end

      def appeal_params
        params.require(:appeal).permit(:reason, :started_at, documents: [])
      end
    end
  end
end
