# frozen_string_literal: true

class Legislation < ApplicationRecord
  has_many :application_types, class_name: "ApplicationType::Config", dependent: :restrict_with_error

  validates :title, presence: true
  validates :title, uniqueness: true
  validates :link, url: true

  attr_readonly :title

  class << self
    def by_title
      order(:title)
    end

    def menu
      by_title.pluck(:title, :id)
    end
  end
end
