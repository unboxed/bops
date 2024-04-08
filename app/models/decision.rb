# frozen_string_literal: true

class Decision < ApplicationRecord
  enum :category, ApplicationType.categories
  enum :code, {granted: "granted", refused: "refused", not_required: "not_required"}

  class << self
    def for_category(category)
      where(category: category)
    end

    def for_codes(codes)
      where(code: Array.wrap(codes))
    end
  end
end
