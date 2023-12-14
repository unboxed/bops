# frozen_string_literal: true

module PermittedDevelopmentRights
  extend ActiveSupport::Concern

  included do
    before_action :set_planning_application
    before_action :raise_routing_error, unless: :permitted_development_rights_can_be_checked?
  end

  def permitted_development_rights_can_be_checked?
    @planning_application.check_permitted_development_rights?
  end

  def set_permitted_development_right
    @permitted_development_right = @planning_application.permitted_development_right
  end

  def set_permitted_development_rights
    @permitted_development_rights = @planning_application.permitted_development_rights.returned
  end

  private

  def raise_routing_error
    raise ActionController::RoutingError, "Not found"
  end
end
