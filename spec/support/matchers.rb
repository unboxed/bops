# frozen_string_literal: true

RSpec::Matchers.define(:have_image_displayed) do |image_name|
  match do |object|
    object.has_css?("img[src*=\"#{image_name}\"]")
  end
end
