# frozen_string_literal: true

class SiteNotice < ApplicationRecord
  belongs_to :planning_application
  has_one :document, dependent: :destroy

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  delegate :consultation, to: :planning_application
  delegate :start_date, to: :consultation, prefix: true
  delegate :end_date, to: :consultation, prefix: true
  delegate :started?, to: :consultation, prefix: true
  delegate :start_deadline, to: :consultation

  before_validation :start_deadline, unless: :consultation_started?
  after_update :extend_consultation!, if: :saved_change_to_displayed_at?

  attr_reader :method

  def preview_content(planning_application)
    start_deadline unless consultation_started?

    I18n.t("site_notice_template",
      council: planning_application.local_authority.subdomain.capitalize,
      reference: planning_application.reference,
      application_description: planning_application.description,
      site_address: planning_application.full_address,
      applicant_name: "#{planning_application.applicant_first_name} #{planning_application.applicant_last_name}",
      application_link: application_link(planning_application),
      council_address: I18n.t("council_addresses.#{planning_application.local_authority.subdomain}"),
      consultation_end_date: consultation_end_date.to_date.to_fs,
      site_notice_display_date: displayed_at&.to_date&.to_fs || Time.zone.today.to_fs)
  end

  private

  def application_link(planning_application)
    if Bops.env.production?
      "https://planningapplications.#{planning_application.local_authority.subdomain}.gov.uk/planning_applications/#{planning_application.id}"
    else
      "https://#{planning_application.local_authority.subdomain}.bops-applicants.services/planning_applications/#{planning_application.id}"
    end
  end

  def new_consultation_end_date
    [displayed_at && (displayed_at + 21.days).end_of_day, consultation_end_date].compact.max
  end

  def extend_consultation!
    consultation.update!(end_date: new_consultation_end_date)
  end
end
