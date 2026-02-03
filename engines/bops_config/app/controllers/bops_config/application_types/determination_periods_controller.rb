# frozen_string_literal: true

module BopsConfig
  module ApplicationTypes
    class DeterminationPeriodsController < ApplicationController
      self.page_key = "application_types"

      before_action :set_application_type

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(application_type_params, :determination_period)
            format.html do
              redirect_to next_path, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def application_type_params
        params.require(:application_type).permit(:determination_period_days)
      end

      def set_application_type
        @application_type = ApplicationType::Config.find(application_type_id)
      end

      def next_path
        if @application_type.configured?
          application_type_path(@application_type)
        else
          edit_application_type_features_path(@application_type)
        end
      end
    end
  end
end
