# frozen_string_literal: true

module PermittedDevelopmentRights
  extend ActiveSupport::Concern

  included do
    before_action unless: :permitted_development_rights_can_be_checked? do
      raise BopsCore::Errors::NotFoundError, "Permitted development rights are not applicable to this planning application"
    end
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
end
