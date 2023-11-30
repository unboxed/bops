# frozen_string_literal: true

module PlanningApplications
  module Validation
    class FeeItemsController < ValidationRequestsController
      before_action :ensure_planning_application_not_validated, only: %i[show validate]
      before_action :ensure_no_open_or_pending_fee_item_validation_request, only: %i[show validate]

      def show
        respond_to do |format|
          format.html
        end
      end

      def validate
        @planning_application.update(fee_items_params)

        respond_to do |format|
          format.html do
            if @planning_application.valid_fee?
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            elsif @planning_application.valid_fee.nil?
              flash.now[:alert] = "Select Yes or No to continue."
              render :show
            else
              redirect_to new_planning_application_validation_other_change_validation_request_path(@planning_application,
                validate_fee: "yes")
            end
          end
        end
      end

      private

      def fee_items_params
        params[:planning_application] ? params.require(:planning_application).permit(:valid_fee) : params.permit(:valid_fee)
      end
    end
  end
end
