# frozen_string_literal: true

module PermittedDevelopmentRightable
  extend ActiveSupport::Concern

  included do
    def permitted_development_right_updated?
      planning_application.permitted_development_rights.count > 1 &&
        permitted_development_right.review_not_started?
    end
  end
end
