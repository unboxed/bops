# frozen_string_literal: true

module BopsConfig
  module ApplicationTypes
    class StatusesController < ApplicationController
      before_action :set_application_type

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(application_type_params)
            format.html { redirect_to @application_type, notice: t(".success") }
          else
            format.html { render :edit }
          end
        end
      end

      private

      def application_type_params
        params.require(:application_type).permit(:status)
      end

      def set_application_type
        @application_type = ApplicationType.find(application_type_id)
      end
    end
  end
end
