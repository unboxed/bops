# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  STATUSES = %w[not_started invalidated in_assessment awaiting_determination to_be_reviewed].freeze
  REVIEWER_STATUSES = %w[awaiting_determination to_be_reviewed].freeze

  APPLICATION_TYPES = ApplicationType::Config::NAME_ORDER

  attribute :view, :enum, values: %w[all mine], default: "mine"
  attribute :application_type, :list
  attribute :sort_key, :string
  attribute :direction, :enum, values: %w[asc desc]
  attribute :status, :list
  attribute :query, :string
  attribute :submit, :string

  validates :query, presence: true, if: :query_submitted?

  define_model_callbacks :initialize, only: :after

  after_initialize :init_filter_options

  def init_filter_options
    self.status ||= statuses
    self.application_type ||= application_types
  end

  def initialize(params = ActionController::Parameters.new)
    run_callbacks :initialize do
      super(filter_params(params))
    end
  end

  def call
    filtered = if valid? && query
      filtered_scope(records_matching_query)
    else
      filtered_scope
    end

    return filtered unless sort_key
    sorted_scope(filtered)
  end

  def statuses
    STATUSES
  end

  def application_types
    APPLICATION_TYPES
  end

  def exclude_others?
    view == "mine"
  end

  def all_applications_title
    I18n.t(all_applications_title_key, scope: "planning_applications.tabs")
  end

  def current_planning_applications
    @current_planning_applications ||= exclude_others? ? my_applications : all_applications
  end

  private

  def filter_params(params)
    params.permit(:view, :query, :sort_key, :direction, :submit, status: [], application_type: [])
  end

  def all_applications_title_key
    exclude_others? ? :all_your_applications : :all_applications
  end

  def my_applications
    if reviewer?
      all_applications.for_user(current_user.id).or(
        all_applications.where(status: REVIEWER_STATUSES + %w[determined]).for_null_users
      )
    else
      all_applications.for_user_and_null_users(current_user.id)
    end
  end

  def all_applications
    @all_applications ||= local_authority.planning_applications.accepted.by_status_order.by_application_type
  end

  def current_user
    @current_user ||= Current.user
  end

  def assessor?
    current_user.assessor?
  end

  def reviewer?
    current_user.reviewer?
  end

  def local_authority
    @local_authority = current_user.local_authority
  end

  def records_matching_query
    records_matching_reference.presence || records_matching_address_search.presence || records_matching_description
  end

  def records_matching_reference
    current_planning_applications.where(
      "LOWER(reference) LIKE ?",
      "%#{query.downcase}%"
    )
  end

  def records_matching_postcode
    current_planning_applications.where(
      "LOWER(replace(postcode, ' ', '')) = ?",
      query.gsub(/\s+/, "").downcase
    )
  end

  def records_matching_description
    current_planning_applications
      .select(sanitized_select_sql)
      .where(where_sql, query_terms)
      .order(rank: :desc)
  end

  def records_matching_address_search
    return records_matching_address unless postcode_query?

    postcode_results = records_matching_postcode
    postcode_results.presence || records_matching_address
  end

  def records_matching_address
    current_planning_applications.where("address_search @@ to_tsquery('simple', ?)", query.split.join(" & "))
  end

  def sanitized_select_sql
    ActiveRecord::Base.sanitize_sql_array([select_sql, query_terms])
  end

  def select_sql
    "planning_applications.*,
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

  def query_submitted?
    submit.present?
  end

  def status_type
    status&.reject(&:empty?)
  end

  def filtered_scope(scope = current_planning_applications)
    scope.where(status: [status_type], application_type: [selected_application_type_ids]).by_created_at_desc
  end

  def sorted_scope(scope = current_planning_applications)
    PlanningApplicationSorter.new(scope:, sort_key:, direction:).call
  end

  def selected_application_type_ids
    local_authority.application_types.where(name: application_type).ids
  end

  def postcode_query?
    query.match?(/^(GIR\s?0AA|[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})$/i)
  end
end
