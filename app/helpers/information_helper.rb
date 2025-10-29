# frozen_string_literal: true

module InformationHelper
  def information_nav_items(planning_application, active_page_key = information_active_page_key)
    [
      {
        text: "Overview",
        href: planning_application_information_path(planning_application),
        active: information_active_page_key?(active_page_key, :overview)
      },
      {
        text: documents_label(planning_application),
        href: planning_application_information_documents_path(planning_application),
        active: information_active_page_key?(active_page_key, :documents)
      },
      {
        text: constraints_label(planning_application),
        href: planning_application_information_constraints_path(planning_application),
        active: information_active_page_key?(active_page_key, :constraints)
      },
      *consultation_navigation_items(planning_application, active_page_key),
      {
        text: site_history_label(planning_application),
        href: planning_application_information_site_history_path(planning_application),
        active: information_active_page_key?(active_page_key, :site_history)
      }
    ]
  end

  private

  def documents_label(planning_application)
    count = planning_application.documents.active.count
    "Documents (#{count})"
  end

  def constraints_label(planning_application)
    if planning_application.constraints_checked?
      count = planning_application.planning_application_constraints.count
      "Constraints (#{count})"
    else
      "Constraints (0)"
    end
  end

  def site_history_label(planning_application)
    count = planning_application.site_histories.count
    "Site history (#{count})"
  end

  def consultees_label(planning_application)
    count = planning_application.consultation&.consultees&.count.to_i
    "Consultees (#{count})"
  end

  def neighbours_label(planning_application)
    count = planning_application.consultation&.neighbours&.count.to_i
    "Neighbours (#{count})"
  end

  def consultation_navigation_items(planning_application, active_page_key)
    return [] unless planning_application.application_type.consultation?

    items = [
      {
        text: consultees_label(planning_application),
        href: planning_application_information_consultees_path(planning_application),
        active: information_active_page_key?(active_page_key, :consultees)
      }
    ]

    if planning_application.application_type.consultation? &&
        planning_application.neighbour_consultation_feature?
      items << {
        text: neighbours_label(planning_application),
        href: planning_application_information_neighbours_path(planning_application),
        active: information_active_page_key?(active_page_key, :neighbours)
      }
    end

    items
  end

  def information_active_page_key?(active_page_key, key)
    active_page_key.to_s == key.to_s
  end

  def information_active_page_key
    page_keys = {
      "documents" => :documents,
      "constraints" => :constraints,
      "consultees" => :consultees,
      "neighbours" => :neighbours,
      "site_histories" => :site_history
    }

    page_keys.fetch(controller_name, :overview)
  end
end
