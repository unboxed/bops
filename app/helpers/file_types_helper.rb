# frozen_string_literal: true

require "file_types"

module FileTypesHelper
  def acceptable_file_mime_types
    FileTypes::ACCEPTED.join(",")
  end
end
