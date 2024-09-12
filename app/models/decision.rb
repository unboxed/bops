# frozen_string_literal: true

class Decision < ApplicationRecord
  CODES = %w[granted not_required refused].freeze

  enum :category, ApplicationType.categories
  enum :code, {granted: "granted", refused: "refused", not_required: "not_required"}

  with_options presence: true do
    validates :category, :code, :description
  end

  class << self
    def codes
      CODES
    end

    def for_category(category)
      where(category: category)
    end

    def for_codes(codes)
      where(code: Array.wrap(codes))
    end

    def all_codes
      CODES.map { |value| [I18n.t(value.to_s), value] }
    end
  end
end
