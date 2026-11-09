# frozen_string_literal: true

class Enforcement::Activity < ApplicationRecord
  include DateValidateable

  belongs_to :enforcement
  has_rich_text :details

  validates :activity_date, presence: true, date: {on_or_before: :current}

  CATEGORIES = %i[
    site_history
  ].freeze

  enum :category, CATEGORIES.index_with(&:to_s)
end
