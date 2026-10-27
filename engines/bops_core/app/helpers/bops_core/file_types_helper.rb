# frozen_string_literal: true

module BopsCore
  module FileTypesHelper
    def acceptable_file_mime_types
      Document::PERMITTED_CONTENT_TYPES.join(",")
    end
  end
end
