# frozen_string_literal: true

module PlanningApplicationHelper
  def days_color(days_left)
    if days_left > 11
      "green"
    elsif days_left.between?(6, 10)
      "yellow"
    else
      "red"
    end
  end

  def exclude_others?
    params[:q] == "exclude_others"
  end

  def role_name
    if current_user.assessor?
      t("user.officer_role")
    else
      t("user.manager_role")
    end
  end

  def proposed_or_existing(planning_application)
    planning_application.work_status == "proposed" ? "No" : "Yes"
  end

  def status_and_type(planning_application)
    if planning_application.work_status == "proposed" && planning_application.application_type == "lawfulness_certificate"
      "Lawful ​Development ​Certificate (Proposed)"
    elsif planning_application.work_status == "existing" && planning_application.application_type == "lawfulness_certificate"
      "Lawful ​Development ​Certificate (Existing)"
    end
  end

  def filter_text
    if current_user.assessor?
      "View my applications"
    else
      "View assessed applications"
    end
  end

  def flooding_constraints
    ["Flood zone", "Flood zone 1", "Flood zone 2", "Flood zone 3"]
  end

  def military_constraints
    ["Explosives & ordnance storage", "Safeguarded land"]
  end

  def ecology_constraints
    ["Special Area of Conservation (SAC)", "Site of Special Scientific Interest (SSSI)",
     "Ancient Semi-Natural Woodland (ASNW)", "Local Wildlife / Biological notification site", "Priority habitat"]
  end

  def heritage_constraints
    ["Listed building", "Conservation Area", "Area of Outstanding Natural Beauty", "National Park",
     "World Heritage Site", "Broads"]
  end

  def policy_constraints
    ["Article 4 area", "Green belt"]
  end

  def tree_constraints
    ["Tree Preservation Order"]
  end

  def other_constraints
    ["Safety hazard area", "Within 3km of the perimeter of an aerodrome"]
  end

  def custom_constraints(constraints)
    constraints - standard_constraints
  end

  def standard_constraints
    [flooding_constraints, military_constraints, ecology_constraints, heritage_constraints, policy_constraints,
     tree_constraints, other_constraints].flatten
  end

  def constraints_group
    { "General Policy": policy_constraints,
      "Heritage & Conservation": heritage_constraints,
      Flooding: flooding_constraints,
      Ecology: ecology_constraints,
      Trees: tree_constraints,
      "Military & Defence": military_constraints }
  end

  def map_link(address)
    "https://google.co.uk/maps/place/#{CGI.escape(address)}"
  end

  def agent_full_name(planning_application)
    [planning_application.agent_first_name, planning_application.agent_last_name].compact.join(" ")
  end

  def agent_contact_details(planning_application)
    [agent_full_name(planning_application),
     planning_application.agent_phone,
     planning_application.agent_email].reject(&:blank?)
  end

  def applicant_full_name(planning_application)
    [planning_application.applicant_first_name, planning_application.applicant_last_name].compact.join(" ")
  end

  def applicant_contact_details(planning_application)
    [applicant_full_name(planning_application),
     planning_application.applicant_phone,
     planning_application.applicant_email].reject(&:blank?)
  end

  def display_status(planning_application)
    if planning_application.determined?
      display_decision_status(planning_application)
    elsif planning_application.status == "invalidated"
      { color: "yellow", decision: "invalid" }
    elsif planning_application.status == "not_started"
      { color: "grey", decision: "Not started" }
    elsif planning_application.status == "in_assessment"
      { color: "turquoise", decision: "In assessment" }
    elsif planning_application.status == "awaiting_determination"
      { color: "purple", decision: "Awaiting determination" }
    elsif planning_application.status == "awaiting_correction"
      { color: "green", decision: "Awaiting correction" }
    else
      { color: "grey", decision: planning_application.status }
    end
  end

  def display_decision_status(planning_application)
    if planning_application.granted?
      { color: "green", decision: "Granted" }
    else
      { color: "red", decision: "Refused" }
    end
  end

  def cancelled_at(planning_application)
    if planning_application.withdrawn?
      planning_application.withdrawn_at
    elsif planning_application.returned?
      planning_application.returned_at
    end
  end

  def display_number(proposal_details, element)
    proposal_details.find_index(element) + 1
  end

  def validation_request_summary(validation_requests, planning_application)
    if planning_application.invalidated?
      "This application has #{pluralize(validation_requests.count(&:open?),
                                        'unresolved validation request')} and #{pluralize(
                                          validation_requests.count(&:closed?), 'resolved validation request'
                                        )}"
    elsif planning_application.validation_requests.none? && (planning_application.recommendable? || planning_application.closed?)
      "This application had no validation requests"
    elsif planning_application.recommendable? || (planning_application.closed? && planning_application.validation_requests.present?)
      "This application has #{pluralize(validation_requests.count(&:closed?), 'resolved validation request')}"
    else
      # FIXME: same body as first branch
      "This application has #{pluralize(validation_requests.count(&:open?),
                                        'unresolved validation request')} and #{pluralize(
                                          validation_requests.count(&:closed?), 'resolved validation request'
                                        )}"
    end
  end

  def received_at(planning_application)
    Time.first_business_day(planning_application.created_at).to_formatted_s(:day_month_year)
  end
end
