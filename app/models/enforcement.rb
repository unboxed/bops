# frozen_string_literal: true

class Enforcement < ApplicationRecord
  include Caseable

  composed_of :address,
    mapping: {
      address_1: :line_1,
      address_2: :line_2,
      town: :town,
      county: :county,
      postcode: :postcode
    }

  after_initialize -> { self.received_at ||= Time.zone.now }

  scope :by_received_at_desc, -> { order(received_at: :desc) }
  delegate :to_s, to: :address

  def to_param
    case_record.id
  end

  def status
    :unknown
  end

  def proposal_details
    Array(super).each_with_index.map do |hash, index|
      ProposalDetail.new(hash, index)
    end
  end

  def status_tag_colour
    "grey"
  end

  def days_from
    created_at.to_date.business_days_until(Time.previous_business_day(Date.current))
  end
end
