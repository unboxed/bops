# frozen_string_literal: true

class Legislation < ApplicationRecord
  has_many :application_types, dependent: :restrict_with_error

  validates :title, presence: true
  validates :title, uniqueness: true
  validates :link, url: true

  class << self
    def by_title
      order(:title)
    end

    def menu
      by_title.pluck(:title, :id)
    end
  end
end
