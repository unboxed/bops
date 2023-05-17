# frozen_string_literal: true

module PermittedDevelopmentRights
  extend ActiveSupport::Concern

  def set_permitted_development_right
    @permitted_development_right = @planning_application.permitted_development_right
  end

  def set_permitted_development_rights
    @permitted_development_rights = @planning_application.permitted_development_rights.returned
  end

  def planning_applications_scope
    current_local_authority.planning_applications
  end
end
