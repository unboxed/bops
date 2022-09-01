# frozen_string_literal: true

RSpec::Matchers.define(:have_image_displayed) do |image_name|
  match do |object|
    object.has_css?("img[src*=\"#{image_name}\"]")
  end
end

RSpec::Matchers.define(:have_row_for) do |content, options|
  include SystemSpecHelpers

  match do |element|
    row = row_with_content(content, element)
    with = options&.fetch(:with, nil)
    with.present? ? row.has_content?(with) : row.present?
  end
end

RSpec::Matchers.define(:have_target_id) do |target_id|
  match { |url| URI.parse(url).fragment == target_id }
end
