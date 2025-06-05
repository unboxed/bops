# frozen_string_literal: true

class LandOwner < ApplicationRecord
  belongs_to :ownership_certificate

  validates :name, presence: true

  before_create do
    self.notice_given = notice_given_at.present?
  end

  def address
    [address_1, address_2, town, county, postcode].compact_blank.join(", ")
  end
end
