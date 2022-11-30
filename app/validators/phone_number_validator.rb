# frozen_string_literal: true

class PhoneNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || value.delete("-+ ()").match(/\A\d{8,15}\z/)

    record.errors.add(attribute, :invalid)
  end
end
