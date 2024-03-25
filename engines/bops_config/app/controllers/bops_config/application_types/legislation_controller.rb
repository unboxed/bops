# frozen_string_literal: true

module BopsConfig
  module ApplicationTypes
    class LegislationController < ApplicationController
      before_action :set_application_type

      def edit
        @legislation = @application_type.existing_or_new_legislation

        respond_to do |format|
          format.html
        end
      end

      def update
        @application_type.attributes = legislation_params
        @legislation = @application_type.existing_or_new_legislation

        respond_to do |format|
          if @application_type.save(context: :legislation)
            format.html { redirect_to next_path, notice: t(".success") }
          else
            format.html { render :edit }
          end
        end
      end

      private

      def application_type_params
        params.require(:application_type).permit(*application_type_attributes)
      end

      def legislation_type
        application_type_params.fetch(:legislation_type)
      end

      def legislation_params
        if legislation_type == "existing"
          application_type_params.slice(:legislation_type, :legislation_id)
        else
          application_type_params.slice(:legislation_type, :legislation_attributes)
        end
      end

      def application_type_attributes
        [:legislation_type, :legislation_id, legislation_attributes: legislation_attributes]
      end

      def legislation_attributes
        %i[title description link]
      end

      def set_application_type
        @application_type = ApplicationType.find(application_type_id)
      end

      def next_path
        if @application_type.configured?
          application_type_path(@application_type)
        else
          edit_application_type_determination_period_path(@application_type)
        end
      end
    end
  end
end
