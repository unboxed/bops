# frozen_string_literal: true

module BopsCore
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
      ApplicationTypeFeature::APPLICATION_DETAILS_FEATURES.keys.sort
    end
  end
end
