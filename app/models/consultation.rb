# frozen_string_literal: true

class Consultation < ApplicationRecord
  belongs_to :planning_application

  with_options dependent: :destroy do
    has_many :consultees
    has_many :neighbours
    has_many :site_visits
  end

  has_many :neighbour_letters, through: :neighbours
  has_many :neighbour_responses, through: :neighbours

  accepts_nested_attributes_for :consultees, :neighbours

  enum status: {
    not_started: "not_started",
    in_progress: "in_progress",
    complete: "complete"
  }

  before_update :audit_letter_copy_sent!, if: :letter_copy_sent_at_changed?

  def start_deadline
    update!(end_date: end_date_from_now, start_date: start_date || 1.business_day.from_now)
  end

  def end_date_from_now
    # Letters are printed at 5:30pm and dispatched the next working day (Monday to Friday)
    # Second class letters are delivered 2 days after they’re dispatched.
    # Royal Mail delivers from Monday to Saturday, excluding bank holidays.
    1.business_day.from_now + 21.days
  end

  def days_left
    (end_date - Time.zone.now).seconds.in_days.round
  end

  def neighbour_letters_failed?
    neighbour_letters.failed.present?
  end

  def neighbour_letters_sent?
    neighbour_letters.sent.present?
  end

  def neighbour_letter_content
    I18n.t("neighbour_letter_template",
           received_at: planning_application.received_at.to_fs(:day_month_year_slashes),
           expiry_date: planning_application.expiry_date.to_fs(:day_month_year_slashes),
           address: planning_application.full_address,
           description: planning_application.description,
           reference: planning_application.reference,
           closing_date: planning_application.received_at.to_fs(:day_month_year_slashes),
           rear_wall: planning_application&.proposal_measurement&.depth,
           max_height: planning_application&.proposal_measurement&.max_height,
           eaves_height: planning_application&.proposal_measurement&.eaves_height,
           application_link:)
  end

  def site_visit
    site_visits.by_created_at_desc.first
  end

  def neighbour_responses_by_summary_tag
    neighbour_responses.group(:summary_tag).count
  end

  private

  def application_link
    "https://#{planning_application.local_authority.subdomain}.bops-applicants.services/planning_applications/#{planning_application.id}"
  end

  def audit_letter_copy_sent!
    Audit.create!(
      planning_application_id:,
      user: Current.user,
      activity_type: "neighbour_letter_copy_mail_sent",
      audit_comment:
        "Neighbour letter copy sent by email to #{planning_application.applicant_and_agent_email.join(', ')}"
    )
  end
end
