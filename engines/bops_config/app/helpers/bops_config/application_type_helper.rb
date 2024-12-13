# frozen_string_literal: true

module BopsConfig
  module ApplicationTypeHelper
    COLOURS = {
      active: "green",
      inactive: "grey",
      retired: "red"
    }.freeze

    def tag_colour(tag)
      COLOURS[tag.to_sym]
    end

    def application_details_features
      %i[
        assess_against_policies
        considerations
        cil
        eia
        informatives
        legislative_requirements
        ownership_details
        planning_conditions
        permitted_development_rights
      ]
    end
  end
end
