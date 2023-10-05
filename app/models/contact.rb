# frozen_string_literal: true

class Contact < ApplicationRecord
  ORIGINS = %w[internal external].freeze
  CATEGORIES = %w[consultee].freeze

  belongs_to :local_authority, optional: true

  validates :origin, inclusion: { in: ORIGINS }
  validates :category, inclusion: { in: CATEGORIES }

  validates :name, presence: true

  class << self
    def search(query, local_authority: nil, category: nil)
      return none if query.blank?

      scope = where(local_authority_id: nil)
      scope = scope.or(where(local_authority:)) if local_authority
      scope = scope.where(category:) if category
      scope = scope.where(search_query, search_param(query))
      scope = scope.limit(10)

      scope.order(:name)
    end

    private

    delegate :quote_column_name, to: :connection

    def search_query
      "#{quoted_table_name}.#{quote_column_name('search')} @@ to_tsquery('simple', ?)"
    end

    def search_param(query)
      query.to_s
           .scan(/[-\w]{3,}/)
           .map { |word| word.gsub(/^-/, "!") }
           .map { |word| word.gsub(/-$/, "") }
           .map { |word| word.gsub(/.+/, "\\0:*") }
           .join(" & ")
    end
  end
end
