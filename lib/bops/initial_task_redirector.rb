# frozen_string_literal: true

class Bops::InitialTaskRedirector
  def initialize(section)
    @section = section
  end

  attr_reader :section

  def call(params, request)
    local_authority = LocalAuthority.find_by!(subdomain: request.subdomain)
    reference = params[:planning_application_reference] || params[:reference]
    planning_application = local_authority.planning_applications.find_by!(reference:)
    task = planning_application.case_record.tasks.find_by(section:)&.first_child

    if planning_application.pre_application?
      BopsPreapps::Engine.routes.url_helpers.task_path(planning_application, task)
    else
      Rails.application.routes.url_helpers.task_path(planning_application, task)
    end
  end
end
