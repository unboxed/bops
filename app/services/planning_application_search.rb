# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model

  attr_accessor :query, :planning_applications

  validates :query, presence: true

  def results
    valid? ? records_matching_query : planning_applications
  end

  private

  def records_matching_query
    records_matching_reference.presence || records_matching_description
  end

  def records_matching_reference
    planning_applications.where(
      "LOWER(reference) LIKE ?",
      "%#{query.downcase}%"
    )
  end

  def records_matching_description
    planning_applications
      .select(sanitized_select_sql)
      .where(where_sql, query_terms)
      .order(rank: :desc)
  end

  def sanitized_select_sql
    ActiveRecord::Base.sanitize_sql_array([select_sql, query_terms])
  end

  def select_sql
    "*,
    ts_rank(
      to_tsvector('english', description),
      to_tsquery('english', ?)
    ) AS rank"
  end

  def where_sql
    "to_tsvector('english', description) @@ to_tsquery('english', ?)"
  end

  def query_terms
    @query_terms ||= query.split.join(" | ")
  end
end
