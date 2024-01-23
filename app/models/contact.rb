# frozen_string_literal: true

class Contact < ApplicationRecord
  belongs_to :local_authority, optional: true

  validates :name, presence: true
  validates :origin, presence: true, if: :consultee?
  validates :email_address, presence: true, if: :consultee?

  with_options format: {with: URI::MailTo::EMAIL_REGEXP} do
    validates :email_address, allow_blank: true
  end

  enum :origin, {
    internal: "internal",
    external: "external"
  }, scopes: false

  enum :category, {
    consultee: "consultee"
  }, scopes: false

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

    def consultees(query)
      scope = where(category: "consultee")
      scope = scope.order(:name)

      if query.blank?
        scope
      else
        scope.where(search_query, search_param(query))
      end
    end

    def build_consultee(attributes = {})
      create_with(category: "consultee").build(attributes)
    end

    def find_consultee(id)
      where(category: "consultee").find(id)
    end

    private

    delegate :quote_column_name, to: :connection

    def search_query
      "#{quoted_table_name}.#{quote_column_name("search")} @@ to_tsquery('simple', ?)"
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
