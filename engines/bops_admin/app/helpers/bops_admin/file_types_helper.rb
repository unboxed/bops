# frozen_string_literal: true

module BopsAdmin
  module FileTypesHelper
    def acceptable_file_mime_types
      FileTypes::ACCEPTED.join(",")
    end
  end
end
