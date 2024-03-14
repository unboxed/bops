# frozen_string_literal: true

class CommitteeDecision < ApplicationRecord
  belongs_to :planning_application

  validates :recommend, exclusion: {in: [nil]}

  before_commit do
    errors.add(:reasons, "Choose reasons why this application should go to committee") if reasons.blank? && recommend
  end

  REASONS = [
    "The application is on council owned land",
    "The application was made by the local authority",
    "The application was submitted by Councillors or officers employed by the council",
    "The application is for new buildings to provide 5 or more new homes (not flats)",
    "The application is for change of use of more than 1000sqm of non-residential floor space",
    "Other"
  ]

  EMAIL_PLACEHOLDER = /\{\{\s*([a-z][_a-z0-9]+)\s*\}\}/

  before_update do
    assign_attributes(reasons: []) if !recommend
  end

  def notification_content
    if super.presence&.include?("{{")
      neighbour_letter_content
    else
      super.presence
    end
  end

  def neighbour_letter_content
    "# #{neighbour_letter_header}\n\n#{neighbour_letter_body}"
  end

  def neighbour_letter_header
    "Town and Country Planning Act 1990"
  end

  def neighbour_letter_body
    body = I18n.t("neighbour_letter_template.committee")

    defaults = {
      address: planning_application.full_address,
      council: planning_application.local_authority.short_name,
      reference: planning_application.reference,
      date_of_committee: planning_application.committee_decision.date_of_committee.to_date.to_fs,
      time: planning_application.committee_decision.time,
      location: planning_application.committee_decision.location,
      decision: planning_application.decision,
      link: planning_application.committee_decision.link,
      current_user: Current.user.name,
      late_comments_deadline: planning_application.committee_decision.late_comments_deadline.to_date.to_fs,
      application_link: application_link(planning_application)
    }

    replace_placeholders(body, defaults)
  end

  private

  def replace_placeholders(string, variables)
    string.to_s.gsub(EMAIL_PLACEHOLDER) { variables.fetch($1.to_sym) }
  end

  def application_link(planning_application)
    "#{planning_application.local_authority.applicants_url}/planning_applications/#{planning_application.id}"
  end
end
