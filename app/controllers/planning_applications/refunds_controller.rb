# frozen_string_literal: true

module PlanningApplications
  class RefundsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_refunds, only: %i[index create destroy]

    def index
      @refund = @refunds.new
      respond_to do |format|
        format.html
      end
    end

    def create
      @refund = @refunds.new(refund_params)

      if @refund.save
        redirect_to planning_application_charges_path(@planning_application), notice: "Refund created successfully."
      else
        set_refunds
        render :index
      end
    end

    def destroy
      @refund = @refunds.find(params[:id])
      if @refund.destroy
        redirect_to planning_application_charges_path(@planning_application), notice: "Refund successfully removed."
      else
        render :index
      end
    end

    private

    def refund_params
      params.require(:refund).permit(:amount, :date, :payment_type, :reference, :reason)
    end

    def set_refunds
      @refunds = @planning_application.refunds
    end
  end
end
