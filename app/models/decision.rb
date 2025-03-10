# frozen_string_literal: true

class Decision < ApplicationRecord
  enum :category, ApplicationType::Config.categories
  enum :code, %i[granted not_required refused].index_with(&:to_s)

  with_options presence: true do
    validates :category, :code, :description
  end

  class << self
    def for_category(category)
      where(category: category)
    end

    def for_codes(codes)
      where(code: Array.wrap(codes))
    end

    def all_codes
      codes.values.map { |value| [I18n.t(value.to_s), value] }
    end
  end
end
