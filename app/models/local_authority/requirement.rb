# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  class Requirement < ApplicationRecord
    enum :category, %i[drawings evidence supporting_documents other].index_with(&:to_s)

    belongs_to :local_authority
    has_and_belongs_to_many :application_types # rubocop:disable Rails/HasAndBelongsToMany

    validates :category, presence: true

    validates :description,
      uniqueness: {scope: :local_authority},
      presence: true

    validates :url, url: true

    CATEGORIES = %w[drawings
      evidence
      supporting_documents
      other].freeze

    class << self
      def search(query)
        scope = order(:description)

        if query.blank?
          scope
        else
          scope.where(search_query, search_param(query))
        end
      end

      def categories
        CATEGORIES
      end

      def cil_requirement_attributes
        I18n.t("local_authority.requirements.cil").deep_symbolize_keys
      end

      def ensure_cil_requirement_for!(local_authority)
        attributes = cil_requirement_attributes

        requirement = local_authority.requirements.find_or_initialize_by(description: attributes[:description])
        requirement.assign_attributes(attributes)
        requirement.save!
        requirement
      end

      private

      delegate :quote_column_name, to: :connection

      def search_query
        "#{quoted_table_name}.#{quote_column_name("search")} @@ to_tsquery('simple', ?)"
      end

      def search_param(query)
        query.to_s
          .scan(/[-\w]{2,}/)
          .map { |word| word.gsub(/^-/, "!") }
          .map { |word| word.gsub(/-$/, "") }
          .map { |word| word.gsub(/.+/, "\\0:*") }
          .join(" & ")
      end
    end
  end
end
