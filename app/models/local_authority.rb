# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :planning_applications, dependent: :destroy
  has_one :api_user, dependent: :destroy

  validates :council_code, :subdomain, :signatory_name, :signatory_job_title, :enquiries_paragraph, :email_address,
            :feedback_email, presence: true

  validates(
    :reviewer_group_email,
    format: { with: URI::MailTo::EMAIL_REGEXP },
    allow_blank: true
  )

  enum subdomain: {
    lambeth: "lambeth",
    southwark: "southwark",
    buckinghamshire: "buckinghamshire",
    ripa: "ripa"
  }

  def signatory
    "#{signatory_name}, #{signatory_job_title}"
  end

  def council_name
    ripa? ? subdomain.capitalize : "#{subdomain.capitalize} Council"
  end

  def staging?
    ENV.fetch("STAGING_ENABLED", "false") == "true"
  end
end
