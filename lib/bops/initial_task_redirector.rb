# frozen_string_literal: true

class Bops::InitialTaskRedirector
  def initialize(section)
    @section = section
  end

  attr_reader :section

  def call(params, request)
    local_authority = LocalAuthority.find_by!(subdomain: request.subdomain)

    if params[:case_id].present?
      case_record = local_authority.case_records.find(params[:case_id])
    elsif params[:caseable_type] == "Enforcement"
      enforcement = local_authority.enforcements.find_by!(reference: params[:reference])
      case_record = enforcement.case_record
    else
      reference = params[:planning_application_reference] || params[:reference]
      planning_application = local_authority.planning_applications.find_by!(reference:)
      case_record = planning_application.case_record
    end
    task = case_record.tasks.find_by(section:)&.first_child

    if planning_application
      if planning_application.pre_application?
        BopsPreapps::Engine.routes.url_helpers.task_path(planning_application, task)
      else
        Rails.application.routes.url_helpers.task_path(planning_application, task)
      end
    elsif case_record.enforcement?
      BopsEnforcements::Engine.routes.url_helpers.task_path(enforcement, task)
    end
  end
end
