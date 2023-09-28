# frozen_string_literal: true

class Neighbour < ApplicationRecord
  belongs_to :consultation
  has_many :neighbour_letters, dependent: :destroy
  has_many :neighbour_responses, dependent: :destroy

  validates :address, presence: true, unless: :not_selected?
  validates :address, uniqueness: {
    scope: :consultation_id, case_sensitive: false, message: lambda { |_object, data|
      "#{data[:value]} has already been added."
    }
  }

  accepts_nested_attributes_for :neighbour_responses

  scope :without_letters, lambda {
                            left_outer_joins(:neighbour_letters)
                              .where(neighbour_letters: { neighbour_id: nil })
                              .where(selected: true)
                          }
  scope :with_letters, lambda {
                         includes([:neighbour_letters])
                           .joins(:neighbour_letters)
                           .where.not(neighbour_letters: { neighbour_id: nil })
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

  private

  def not_selected?
    selected == false
  end
end
