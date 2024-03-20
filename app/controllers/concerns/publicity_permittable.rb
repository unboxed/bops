# frozen_string_literal: true

module PublicityPermittable
  extend ActiveSupport::Concern

  def ensure_publicity_is_permitted
    return if @planning_application.publicity_consultation_feature?

    raise ActionController::RoutingError, "Not found"
  end
end
