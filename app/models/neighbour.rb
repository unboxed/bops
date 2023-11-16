# frozen_string_literal: true

class Neighbour < ApplicationRecord
  class AddressValidationError < StandardError; end

  belongs_to :consultation
  has_many :neighbour_letters, dependent: :destroy
  has_many :neighbour_responses, dependent: :destroy

  validates :address, presence: true, unless: :not_selected?
  validates :address, uniqueness: {
    scope: :consultation_id, case_sensitive: false, message: lambda { |_object, data|
      "#{data[:value]} has already been added."
    }
  }

  validate :validate_address_format

  accepts_nested_attributes_for :neighbour_responses

  scope :without_letters, lambda {
                            left_outer_joins(:neighbour_letters)
                              .where(neighbour_letters: {neighbour_id: nil})
                              .where(selected: true)
                          }
  scope :with_letters, lambda {
                         includes([:neighbour_letters])
                           .joins(:neighbour_letters)
                           .where.not(neighbour_letters: {neighbour_id: nil})
                       }

  def last_letter
    neighbour_letters.last
  end

  def letter_created?
    neighbour_letters.present?
  end

  def letter_sent?
    letter_created? && neighbour_letters.any? { |letter| letter.sent_at.present? }
  end

  def validate_address_format
    return if address.blank?

    errors.add(:address, address_validation_error_message) unless valid_address_format?
  end

  def format_address_lines
    # GOV.UK Notify expects at least 3 lines for the address
    raise AddressValidationError, address_validation_error_message unless valid_address_format?

    ["The Occupier", *split_address_on_commas].each_with_index.to_h do |line, i|
      ["address_line_#{i + 1}", line]
    end
  end

  private

  def not_selected?
    selected == false
  end

  def split_address_on_commas
    # split on commas unless preceded by digits (i.e. house numbers)
    address.split(/(?<!\d), */).compact
  end

  def valid_address_format?
    split_address_on_commas.length >= 2
  end

  def address_validation_error_message
    <<~ERROR
      '#{address}' is invalid
      Enter the property name or number, followed by a comma
      Enter the street name, followed by a comma
      Enter a postcode, like AA11AA
    ERROR
  end
end
