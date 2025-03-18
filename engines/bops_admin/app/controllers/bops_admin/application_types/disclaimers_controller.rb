# frozen_string_literal: true

module BopsAdmin
  module ApplicationTypes
    class DisclaimersController < ApplicationController
      before_action :set_application_type

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(application_type_params, :disclaimer)
            format.html do
              redirect_to @application_type, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def application_type_params
        params.require(:application_type).permit(:disclaimer)
      end

      def set_application_type
        @application_type = current_local_authority.application_types.find(application_type_id)
      end

      def application_type_id
        Integer(params[:application_type_id])
      end
    end
  end
end
