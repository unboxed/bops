# frozen_string_literal: true

module BopsConfig
  module ApplicationTypes
    class FeaturesController < ApplicationController
      before_action :set_application_type

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(features_params, :features)
            format.html do
              redirect_to next_path, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def features_params
        params.require(:application_type).permit(features: features_attributes)
      end

      def features_attributes
        [
          :appeals,
          :assess_against_policies,
          :cil,
          :considerations,
          :consultations_skip_bank_holidays,
          :description_change_requires_validation,
          :eia,
          :informatives,
          :legislative_requirements,
          :ownership_details,
          :permitted_development_rights,
          :planning_conditions,
          :publishable,
          :site_visits,
          {consultation_steps: []}
        ]
      end

      def set_application_type
        @application_type = ApplicationType::Config.find(application_type_id)
      end

      def next_path
        if @application_type.configured?
          application_type_path(@application_type)
        else
          edit_application_type_document_tags_path(@application_type)
        end
      end
    end
  end
end
