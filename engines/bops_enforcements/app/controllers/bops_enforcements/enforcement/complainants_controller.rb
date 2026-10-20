# frozen_string_literal: true

module BopsEnforcements
  class Enforcement::ComplainantsController < ApplicationController
    before_action :set_enforcement

    def create
      @enforcement_complainant = @enforcement.complainants.new(complainant_params)

      respond_to do |format|
        if @enforcement_complainant.save
          format.html { redirect_to @enforcement, notice: "Complainant was successfully added" }
        else
          flash[:complainant_params] = complainant_params
          flash[:complainant_errors] = @enforcement_complainant.errors
          format.html { redirect_to @enforcement, alert: "Failed to add complainant" }
        end
      end
    end

    private

    def set_enforcement
      @enforcement = current_local_authority
        .enforcements.find_by!(reference: params[:reference])
    end

    def complainant_params
      params.require(:enforcement_complainant).permit(%i[first_name last_name email address_1 address_2 town county postcode])
    end
  end
end
