# frozen_string_literal: true

module PlanningApplicationDecorator
  extend ActiveSupport::Concern

  def agent_full_name
    [agent_first_name, agent_last_name].compact.join(" ")
  end

  def agent_contact_details
    [agent_full_name, agent_phone, agent_email].reject(&:blank?)
  end

  def applicant_full_name
    [applicant_first_name, applicant_last_name].compact.join(" ")
  end

  def applicant_contact_details
    [applicant_full_name, applicant_phone, applicant_email].reject(&:blank?)
  end

  def applicant_name
    "#{applicant_first_name} #{applicant_last_name}"
  end

  def full_address
    "#{address_1}, #{town}, #{postcode}"
  end

  def type
    I18n.t(application_type, scope: "application_types")
  end

  def type_and_work_status
    "#{type} (#{work_status.humanize})"
  end
end
