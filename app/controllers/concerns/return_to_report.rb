# frozen_string_literal: true

# Simplified return path handling - no session storage needed.
#
# Usage:
#   1. Include this concern in your controller
#   2. Use `return_to_path` in controllers and views for redirect/link destinations
#   3. Forms should include: <%= form.hidden_field :return_to, value: return_to_param %>
#      This ensures the return_to survives validation failures
#
# The return_to param can be:
#   - "report" - redirects to report page (pre-applications only)
#   - A relative path (starting with /) - redirects to that path
#   - nil/absent - uses the default tasks path
#
module ReturnToReport
  extend ActiveSupport::Concern

  RETURN_TO_REPORT = "report"

  included do
    helper_method :return_to_path, :return_to_param
  end

  private

  # Returns the appropriate path for redirects and back links.
  # Pass a default_path for when return_to is not specified.
  def return_to_path(default_path = nil)
    resolve_return_to(return_to_param) || default_path || default_tasks_path
  end

  # Get the return_to value from params (supports nested params too)
  def return_to_param
    # Check top-level params first, then common nested locations
    params[:return_to].presence ||
      params[:redirect_to].presence ||
      params.dig(controller_name.singularize.to_sym, :return_to).presence
  end

  # Resolve the return_to value to an actual path
  def resolve_return_to(value)
    case value
    when RETURN_TO_REPORT
      bops_reports.planning_application_path(@planning_application) if @planning_application&.pre_application?
    when /\A\//
      # Allow relative paths (starting with /) for security
      value
    end
  end

  def default_tasks_path
    if controller_path.include?("validation")
      planning_application_validation_tasks_path(@planning_application)
    else
      planning_application_assessment_tasks_path(@planning_application)
    end
  end

  # DEPRECATED: These methods are kept for backwards compatibility during migration
  # Remove once all controllers are updated

  def store_return_to_report_path
    # No-op: session storage no longer needed
  end

  def back_path(default_path = nil)
    return_to_path(default_path)
  end

  def report_path_or(default_path)
    return_to_path(default_path)
  end

  def should_return_to_report?
    return_to_param == RETURN_TO_REPORT && @planning_application&.pre_application?
  end
end
