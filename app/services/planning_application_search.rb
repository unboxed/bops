# frozen_string_literal: true

class PlanningApplicationSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  STATUSES = %w[not_started invalidated in_assessment awaiting_determination to_be_reviewed closed withdrawn determined returned].freeze
  SELECTED_STATUSES = %w[not_started invalidated in_assessment awaiting_determination to_be_reviewed].freeze

  GROUPED_STATUSES = {
    "in_assessment" => %w[in_assessment assessment_in_progress]
  }.freeze

  APPLICATION_TYPES = ApplicationType::Config::NAME_ORDER

  attribute :application_type, :list
  attribute :sort_key, :string
  attribute :direction, :enum, values: %w[asc desc]
  attribute :status, :list
  attribute :query, :string
  attribute :submit, :string

  validates :query, presence: true, if: :query_submitted?

  def initialize(params = ActionController::Parameters.new)
    super(filter_params(params))
    self.status ||= default_statuses
    self.application_type ||= application_types
  end

  def filtered_planning_applications(scope = all_applications)
    scope = apply_filters(scope)
    scope = apply_text_search(scope)
    apply_sorting(scope)
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

  def closed_planning_applications(scope = all_applications)
    scope = scope.closed_or_cancelled.for_current_user.by_created_at_desc
    scope = apply_text_search(scope)
    apply_sorting(scope)
  end

  def updated_planning_application_audits(limit: 20)
    audited_applications = apply_filters(all_applications)

    audits_scope = audits_for_applications(audited_applications.select(:id))

    if valid? && query
      matching_ids = text_search_filter
        .apply(audited_applications, search_params)
        .unscope(:select, :order)
        .select(:id)
      audits_scope = audits_scope.where(planning_application_id: matching_ids)
    end

    audits_scope.limit(limit)
  end

  def unstarted_prior_approvals
    all_applications.prior_approvals.not_started.for_current_user
  end

  def pre_applications
    @pre_applications ||= all_applications.pre_applications
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
    @local_authority ||= current_user.local_authority
  end

  def query_submitted?
    submit.present?
  end

  def filters
    @filters ||= [
      BopsCore::Filters::StatusFilter.new,
      BopsCore::Filters::ApplicationTypeFilter.new
    ]
  end

  def apply_filters(scope)
    result = filters.reduce(scope) do |s, filter|
      filter.applicable?(search_params) ? filter.apply(s, search_params) : s
    end
    result.by_created_at_desc
  end

  def apply_text_search(scope)
    return scope unless valid? && query.present?

    text_search_filter.apply(scope, search_params)
  end

  def text_search_filter
    @text_search_filter ||= BopsCore::Filters::TextSearch::CascadingSearch.new
  end

  def apply_sorting(scope)
    case sort_key
    when "expiry_date"
      scope.reorder(expiry_date: direction)
    else
      scope
    end
  end

  def audits_for_applications(application_ids)
    local_authority.audits
      .most_recent_for_planning_applications
      .where(planning_application_id: application_ids)
  end

  def search_params
    @search_params ||= {
      status: status,
      application_type: application_type,
      query: query,
      submit: submit
    }
  end
end
