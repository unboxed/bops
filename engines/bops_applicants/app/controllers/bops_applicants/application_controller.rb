# frozen_string_literal: true

module BopsApplicants
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    before_action :require_local_authority!
    helper_method :access_control_params

    def render(options = {}, locals = {}, &)
      flash_options = (Hash === options) ? options : locals

      self.class._flash_types.each do |flash_type|
        if (value = flash_options.delete(flash_type))
          flash.now[flash_type] = value
        end
      end

      if (other_flashes = flash_options.delete(:flash))
        other_flashes.each do |key, value|
          flash.now[key] = value
        end
      end

      super
    end

    private

    def set_planning_application
      if planning_application_param.present?
        @planning_application = planning_applications_scope.find_by_param!(planning_application_param)
      else
        raise BopsCore::Errors::NotFoundError, "Missing planning application reference parameter"
      end
    end

    def access_control_params
      {
        planning_application_reference: @planning_application.reference,
        change_access_id: @planning_application.change_access_id
      }
    end
  end
end
