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

  def filter_text
    if current_user.assessor?
      "View my applications"
    else
      "View assessed applications"
    end
  end

  def flooding_constraints
    { flood_zone: "Flood zone", flood_zone_1: "Flood zone 1", flood_zone_2: "Flood zone 2", flood_zone_3: "Flood zone 3" }
  end

  def military_constraints
    { explosives: "Explosives & ordnance storage", safeguarded: "Safeguarded land" }
  end

  def ecology_constraints
    {  sac: "Special Area of Conservation (SAC)",
       sssi: "Site of Special Scientific Interest (SSSI)",
       asnw: "Ancient Semi-Natural Woodland (ASNW)",
       local_wildlife_site: "Local Wildlife / Biological notification site",
       priority_habitat: "Priority habitat" }
  end

  def heritage_constraints
    { listed_building: "Listed building",
      conservation_area: "Conservation Area",
      aonb: "Area of Outstanding Natural Beauty",
      national_park: "National Park",
      world_heritage_site: "World Heritage Site",
      broads: "Broads" }
  end

  def policy_constraints
    { article_4: "Article 4 area",
      green_belt: "Green belt" }
  end

  def tree_constraints
    { tpo: "Tree Preservation Order" }
  end

  def other_constraints
    {
      safety_hazard: "Safety hazard area",
      aerodrome: "Within 3km of the perimeter of an aerodrome",
    }
  end

  def constraints_dictionary
    [flooding_constraints,
     military_constraints,
     heritage_constraints,
     ecology_constraints,
     tree_constraints,
     policy_constraints,
     other_constraints].reduce(&:merge)
  end

  def original_constraints(constraints)
    filtered_constraints = JSON.parse(constraints)
                               .reject { |k, v| constraints_dictionary.keys.include?(k.to_sym) || v == false }
                               .reject { |k, _v| k.include?("constraint") }
    filtered_constraints.invert unless filtered_constraints.nil?
  end

  def check_added?(constraints, text)
    valid_constraints = filtered_constraints(constraints)
    correct = valid_constraints.map { |element| element.gsub("constraint-", "") }
    correct.include?(text.to_s) ? true : false
  end

  def filtered_constraints(constraints)
    unless constraints.empty?
      parsed_constraints = JSON.parse(constraints)
                               .reject { |_k, v| v == false }
    end
    parsed_constraints.keys
  end

  def map_link(address)
    "https://google.co.uk/maps/place/#{CGI.escape(address)}"
  end

  def constraints_list(constraints)
    valid_constraints = filtered_constraints(constraints)
    valid_constraints.map do |item|
      if constraints_dictionary.keys.include?(item.gsub("constraint-", "").to_sym)
        constraints_dictionary[item.gsub("constraint-", "").to_sym]
      else
        item
      end
    end
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
end
