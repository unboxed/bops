# frozen_string_literal: true

module PlanningApplications
  class PreapplicationServicesController < AuthenticationController
    before_action :set_planning_application
    before_action :redirect_to_reference_url
    before_action :redirect_unless_preapp

    def edit
    end

    def update
      services = preapplication_services_names.map { |name| @planning_application.preapplication_services.find_or_initialize_by(name: name) }
      if (@planning_application.preapplication_services = services).map(&:save)
        redirect_to planning_application_path(@planning_application), notice: t(".success")
      else
        render :edit
      end
    end

    private

    def preapplication_services_names
      params.require(:planning_application).require(:preapplication_services).select(&:present?).map(&:to_sym)
    end

    def redirect_unless_preapp
      return if @planning_application.preapplication?

      redirect_to @planning_application, alert: "Cannot edit pre-application services on application of type ‘#{@planning_application.application_type.full_name}’"
    end
  end
end
