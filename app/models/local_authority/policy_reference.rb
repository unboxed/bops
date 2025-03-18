# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  class PolicyReference < ApplicationRecord
    belongs_to :local_authority
    has_and_belongs_to_many :policy_areas # rubocop:disable Rails/HasAndBelongsToMany

    validates :code,
      uniqueness: {scope: :local_authority},
      presence: true

    validates :description,
      uniqueness: {scope: :local_authority},
      presence: true

    validates :url, url: true

    class << self
      def default_scope
        preload(:policy_areas)
      end

      def search(query)
        scope = by_code

        if query.blank?
          scope
        else
          scope.where(search_query, search_param(query))
        end
      end

      def by_code
        order(:code)
      end

      private

      delegate :quote_column_name, to: :connection

      def search_query
        "#{quoted_table_name}.#{quote_column_name("search")} @@ to_tsquery('simple', ?)"
      end

      def search_param(query)
        query.to_s
          .scan(/[-\w]{1,}/)
          .map { |word| word.gsub(/^-/, "!") }
          .map { |word| word.gsub(/-$/, "") }
          .map { |word| word.gsub(/.+/, "\\0:*") }
          .join(" & ")
      end
    end

    def human_policy_areas
      policy_areas.map(&:description).join(", ")
    end
  end
end
