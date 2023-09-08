# frozen_string_literal: true

class Neighbour < ApplicationRecord
  belongs_to :consultation
  has_one :neighbour_letter, dependent: :destroy
  has_many :neighbour_responses, dependent: :destroy

  validates :address, presence: true, unless: :response_present?
  validates :address, uniqueness: {
    scope: :consultation_id, case_sensitive: false, message: lambda { |_object, data|
      "#{data[:value]} has already been added."
    }
  }

  accepts_nested_attributes_for :neighbour_responses

  scope :without_letters, lambda {
                            left_outer_joins(:neighbour_letter)
                              .where(neighbour_letter: { neighbour_id: nil })
                              .where(selected: true)
                          }
  scope :with_letters, lambda {
                         includes([:neighbour_letter])
                           .joins(:neighbour_letter)
                           .where.not(neighbour_letter: { neighbour_id: nil })
                       }

  def letter_created?
    neighbour_letter.present?
  end

  def letter_sent?
    letter_created? && neighbour_letter.sent_at.present?
  end

  private

  def response_present?
    neighbour_responses.any?
  end
end
