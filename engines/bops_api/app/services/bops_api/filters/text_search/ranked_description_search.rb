# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class RankedDescriptionSearch < BaseSearch
        class << self
          def apply(scope, query)
            terms = tsquery_terms(query)
            scope
              .select(sanitized_select_sql(terms))
              .where(where_sql, terms)
              .order(rank: :desc)
          end

          def sanitized_select_sql(terms)
            ActiveRecord::Base.sanitize_sql_array([select_sql, terms])
          end

          def select_sql
            <<~SQL.squish
              planning_applications.*,
              ts_rank(
                to_tsvector('english', description),
                to_tsquery('english', ?)
              ) AS rank
            SQL
          end

          def where_sql
            "to_tsvector('english', description) @@ to_tsquery('english', ?)"
          end

          def tsquery_terms(query)
            query.split.join(" | ")
          end
        end
      end
    end
  end
end
