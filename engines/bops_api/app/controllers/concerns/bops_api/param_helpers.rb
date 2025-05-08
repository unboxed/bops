# frozen_string_literal: true

module BopsApi
  module ParamHelpers
    extend ActiveSupport::Concern

    # when a parameter is an array of comma-separated values, this method will split them into an array
    def handle_comma_separated_param(param)
      Array(param).flat_map { |v| v.to_s.split(",") }.compact_blank.uniq
    end
  end
end
