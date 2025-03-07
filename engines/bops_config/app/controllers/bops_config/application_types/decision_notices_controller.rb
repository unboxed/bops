# frozen_string_literal: true

module BopsConfig
  module ApplicationTypes
    class DecisionNoticesController < ApplicationController
      before_action :set_application_type

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(application_type_params, :decision_notice)
            format.html do
              redirect_to next_path, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def set_application_type
        @application_type = ApplicationType.find(application_type_id)
      end

      def application_type_params
        params.require(:application_type).permit(*application_type_attributes)
      end

      def application_type_attributes
        [decision_notice_attributes: decision_notice_attributes]
      end

      def decision_notice_attributes
        %i[template status]
      end

      def next_path
        application_type_path(@application_type)
      end
    end
  end
end
