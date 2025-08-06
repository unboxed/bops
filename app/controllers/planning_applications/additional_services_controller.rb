# frozen_string_literal: true

module PlanningApplications
  class AdditionalServicesController < AuthenticationController
    before_action :set_planning_application
    before_action :redirect_to_reference_url
    before_action :redirect_unless_preapp

    def edit
    end

    def update
      services = additional_services_names.map { |name| @planning_application.additional_services.find_or_initialize_by(name: name) }
      if (@planning_application.additional_services = services).map(&:save)
        redirect_to planning_application_path(@planning_application), notice: t(".success")
      else
        render :edit
      end
    end

    private

    def additional_services_names
      params.require(:planning_application).require(:additional_services).compact_blank.map(&:to_sym)
    end

    def redirect_unless_preapp
      # this will need to change if we support additional services on anything but preapps
      return if @planning_application.pre_application?

      redirect_to @planning_application, alert: "Cannot edit pre-application services on application of type ‘#{@planning_application.application_type.full_name}’"
    end
  end
end
