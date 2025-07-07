# frozen_string_literal: true

class Enforcement < ApplicationRecord
  include Caseable
  composed_of :address,
    mapping: {
      address_line_1: :line_1,
      address_line_2: :line_2,
      town: :town,
      county: :county,
      postcode: :postcode
    }

  after_initialize -> { self.received_at ||= Time.zone.now }

  def to_param
    case_record.id
  end

  def status
    :unknown
  end
end
