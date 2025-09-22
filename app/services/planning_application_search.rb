# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  STATUSES = %w[not_started invalidated in_assessment awaiting_determination to_be_reviewed closed withdrawn determined returned].freeze
  SELECTED_STATUSES = %w[not_started invalidated in_assessment awaiting_determination to_be_reviewed].freeze

  APPLICATION_TYPES = ApplicationType::Config::NAME_ORDER

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
    self.status ||= default_statuses
    self.application_type ||= application_types
  end

  def initialize(params = ActionController::Parameters.new)
    run_callbacks :initialize do
      super(filter_params(params))
    end
  end

  def filtered_planning_applications
    scope = filtered_scope(all_applications)

    if valid? && query
      scope = records_matching_query(scope)
    end

    sorted_scope(scope, sort_key, direction)
  end

  def all_statuses
    STATUSES
  end

  def default_statuses
    SELECTED_STATUSES
  end

  def application_types
    APPLICATION_TYPES
  end

  def reviewer_planning_applications
    all_applications.to_be_reviewed.for_current_user
  end

  def closed_planning_applications
    all_applications.closed_or_cancelled.for_current_user
  end

  def unstarted_prior_approvals
    all_applications.prior_approvals.not_started.for_current_user
  end

  private

  def filter_params(params)
    params.permit(:query, :sort_key, :direction, :submit, status: [], application_type: [])
  end

  def all_applications
    @all_applications ||= local_authority.planning_applications.accepted.by_status_order.by_application_type.preload(
      {application_type: :config},
      {case_record: :user}
    )
  end

  def current_user
    @current_user ||= Current.user
  end

  def local_authority
    @local_authority = current_user.local_authority
  end

  def records_matching_query(scope)
    records_matching_reference(scope).presence ||
      records_matching_address_search(scope).presence ||
      records_matching_description(scope)
  rescue ActiveRecord::StatementInvalid
    scope.none
  end

  def records_matching_reference(scope)
    scope.where(
      "LOWER(reference) LIKE ?",
      "%#{query.downcase}%"
    )
  end

  def records_matching_postcode(scope)
    scope.where(
      "LOWER(replace(postcode, ' ', '')) = ?",
      query.gsub(/\s+/, "").downcase
    )
  end

  def records_matching_description(scope)
    scope
      .select(sanitized_select_sql)
      .where(where_sql, query_terms)
      .order(rank: :desc)
  end

  def records_matching_address_search(scope)
    return records_matching_address(scope) unless postcode_query?

    records_matching_postcode(scope).presence || records_matching_address(scope)
  end

  def records_matching_address(scope)
    scope.where("address_search @@ to_tsquery('simple', ?)", query.split.join(" & "))
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

  def selected_statuses
    @selected_statuses ||= status&.reject(&:empty?)
  end

  def filtered_scope(scope)
    filters = {}
    filters[:status] = selected_statuses if selected_statuses.present?
    filters[:application_type] = selected_application_type_ids if selected_application_type_ids.present?

    scope.where(**filters).by_created_at_desc
  end

  def sorted_scope(scope, sort_key, direction)
    case sort_key
    when "expiry_date"
      scope.reorder(expiry_date: direction)
    else
      scope
    end
  end

  def selected_application_type_ids
    @selected_application_type_ids ||= local_authority.application_types.where(name: application_type).ids
  end

  def postcode_query?
    query.match?(/^(GIR\s?0AA|[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})$/i)
  end
end
