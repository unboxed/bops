# frozen_string_literal: true

module BopsAdmin
  module ApplicationTypes
    class RequirementsController < SettingsController
      before_action :set_application_type
      before_action :set_requirements

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(application_type_params)
            format.html do
              redirect_to @application_type, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def application_type_id
        Integer(params[:application_type_id])
      end

      def set_application_type
        @application_type = current_local_authority.application_types.find(application_type_id)
      end

      def set_requirements
        @requirements = current_local_authority.requirements
      end

      def application_type_params
        params.require(:application_type).permit(requirement_ids: [])
      end
    end
  end
end
