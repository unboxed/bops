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
  end
end
