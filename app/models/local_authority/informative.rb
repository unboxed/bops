# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  class Informative < ApplicationRecord
    belongs_to :local_authority

    validates :title, :text, presence: true

    class << self
      def all_informatives(query)
        scope = order(:title)

        if query.blank?
          scope
        else
          scope.where(search_query, search_param(query))
        end
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
end
