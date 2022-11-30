# frozen_string_literal: true

class MobileNumberForm
  include ActiveModel::Model

  attr_accessor :mobile_number

  validates :mobile_number, presence: true, phone_number: true
end
