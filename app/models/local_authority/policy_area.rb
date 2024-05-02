# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  class PolicyArea < ApplicationRecord
    belongs_to :local_authority
    has_and_belongs_to_many :policy_references # rubocop:disable Rails/HasAndBelongsToMany

    validates :description,
      uniqueness: {scope: :local_authority},
      presence: true

    class << self
      def menu
        by_description.pluck(:id, :description)
      end

      def search(query)
        scope = by_description

        if query.blank?
          scope
        else
          scope.where(search_query, search_param(query))
        end
      end

      def by_description
        order(:description)
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
