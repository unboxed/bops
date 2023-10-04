# frozen_string_literal: true

class SiteNotice < ApplicationRecord
  belongs_to :planning_application
  has_one :document, dependent: :destroy

  attr_reader :method

  def preview_content(planning_application)
    I18n.t("site_notice_template",
           council: planning_application.local_authority.subdomain.capitalize,
           reference: planning_application.reference,
           application_description: planning_application.description,
           site_address: planning_application.full_address,
           applicant_name: "#{planning_application.applicant_first_name} #{planning_application.applicant_last_name}",
           application_link: application_link(planning_application),
           council_address: I18n.t("council_addresses.#{planning_application.local_authority.subdomain}"),
           consultation_end_date: end_date_from_now.to_date.to_fs,
           site_notice_display_date: displayed_at&.to_date&.to_fs || Time.zone.today.to_fs)
  end

  def end_date_from_now
    if displayed_at.present?
      displayed_at + 21.days
    else
      Time.zone.today + 23.days
    end
  end

  private

  def application_link(planning_application)
    if Bops.env.production?
      "https://planningapplications.#{planning_application.local_authority.subdomain}.gov.uk/planning_applications/#{planning_application.id}"
    else
      "https://#{planning_application.local_authority.subdomain}.bops-applicants.services/planning_applications/#{planning_application.id}"
    end
  end
end
