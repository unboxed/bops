# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  STATUSES = %w[not_started invalidated in_assessment awaiting_determination to_be_reviewed].freeze
  REVIEWER_STATUSES = %w[awaiting_determination to_be_reviewed].freeze

  attribute :view, :enum, values: %w[all mine], default: "mine"
  attribute :status, :list
  attribute :query, :string
  attribute :submit, :string

  validates :query, presence: true, if: :query_submitted?

  define_model_callbacks :initialize, only: :after

  after_initialize :init_status

  def init_status
    self.status ||= statuses
  end

  def initialize(params = ActionController::Parameters.new)
    run_callbacks :initialize do
      super(filter_params(params))
    end
  end

  def call
    if valid?
      if query
        records_matching_query.where(status: [status_type])
      else
        current_planning_applications&.where(status: [status_type])
      end
    else
      current_planning_applications&.where(status: [status_type])
    end
  end

  def status_type
    status&.reject(&:empty?)
  end

  def statuses
    if reviewer? && exclude_others?
      REVIEWER_STATUSES
    else
      STATUSES
    end
  end

  def exclude_others?
    view == "mine"
  end

  def all_applications_title
    I18n.t(all_applications_title_key, scope: "planning_applications.tabs")
  end

  def current_planning_applications
    @current_planning_applications ||= view_mine? ? my_applications : all_applications
  end

  private

  def filter_params(params)
    params.permit(:view, :query, :submit, status: [])
  end

  def view_mine?
    exclude_others? && assessor?
  end

  def all_applications_title_key
    exclude_others? ? :all_your_applications : :all_applications
  end

  def my_applications
    all_applications.for_user_and_null_users(current_user.id)
  end

  def all_applications
    @all_applications ||= local_authority.planning_applications.includes([:application_type]).by_created_at_desc
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
    records_matching_reference.presence || records_matching_description
  end

  def records_matching_reference
    current_planning_applications.where(
      "LOWER(reference) LIKE ?",
      "%#{query.downcase}%"
    )
  end

  def records_matching_description
    current_planning_applications
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

  def query_submitted?
    submit.present?
  end
end
