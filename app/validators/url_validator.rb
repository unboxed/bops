# frozen_string_literal: true

require "uri"

class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    unless valid_url?(value)
      record.errors.add(attribute, :invalid)
    end
  end

  private

  def valid_url?(value)
    URI::HTTP === URI.parse(value)
  rescue URI::InvalidURIError
    false
  end
end
