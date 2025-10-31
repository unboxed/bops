# frozen_string_literal: true

require "mail"

class EmailValidator < ActiveModel::EachValidator
  HOST = "(?i-mx:xn-|[a-z0-9])(?i-mx:[-a-z0-9]*)"
  TLD = "(?i-mx:[a-z]{2,63}|xn--(?i-mx:[a-z0-9]+-)*[a-z0-9]+)"
  LOCAL = "(?i-mx:[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)"

  EMAIL_REGEX = /\A#{LOCAL}(?:\.#{LOCAL})*@(?:#{HOST}\.)+#{TLD}\z/

  def validate_each(record, attribute, value)
    if value.match?(EMAIL_REGEX)
      Mail::Address.new(value)
    else
      record.errors.add attribute, :invalid
    end
  rescue Mail::Field::ParseError
    record.errors.add attribute, :invalid
  end
end
