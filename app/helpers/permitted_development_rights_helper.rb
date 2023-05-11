# frozen_string_literal: true

module PermittedDevelopmentRightsHelper
  def page_title(planning_application)
    if planning_application.possibly_immune?
      "Immunity/permitted development rights"
    else
      "Permitted development rights"
    end
  end
end
