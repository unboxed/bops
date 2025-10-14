# frozen_string_literal: true

module PlanningApplications
  class ChargesController < AuthenticationController
    before_action :set_planning_application

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      @charge = @planning_application.charges.build
      @payment = @charge.build_payment

      respond_to do |format|
        format.html
      end
    end

    def create
      @charge = @planning_application.charges.new(charge_params)
      if @charge.save
        redirect_to planning_application_charges_path(@planning_application), notice: "Charge created successfully."
      else
        render :new, notice: "Unable to create charge."
      end
    end

    def edit
      @charge = @planning_application.charges.find(params[:id])
      @charge.build_payment unless @charge.payment

      respond_to do |format|
        format.html
      end
    end

    def update
      @charge = @planning_application.charges.find(params[:id])
      @charge.build_payment unless @charge.payment

      if @charge.update(charge_params)
        redirect_to planning_application_charges_path(@planning_application), notice: "Charge updated successfully."
      else
        render :edit, notice: "Unable to update record."
      end
      respond_to do |format|
        format.html
      end
    end

    def destroy
      @charge = @planning_application.charges.find(params[:id])
      if @charge.destroy
        redirect_to planning_application_charges_path(@planning_application), notice: "Charge successfully removed."
      else
        render :edit, notice: "Unable to remove record."
      end
    end

    private

    def charge_params
      params.require(:charge).permit(
        :amount,
        :description,
        :payment_due_date,
        payment_attributes: [:id, :amount, :payment_date, :payment_type, :reference]
      )
    end
  end
end
