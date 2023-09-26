# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :planning_applications, dependent: :destroy
  has_many :audits, through: :planning_applications
  has_many :constraints, dependent: :destroy
  has_one :api_user, dependent: :destroy

  validates :council_code, :subdomain, :signatory_name, :signatory_job_title, :enquiries_paragraph, :email_address,
            :feedback_email, presence: true

  validates(
    :reviewer_group_email,
    format: { with: URI::MailTo::EMAIL_REGEXP },
    allow_blank: true
  )

  validate :council_code_exists

  def signatory
    "#{signatory_name}, #{signatory_job_title}"
  end

  def council_name
    plan_x? ? subdomain.capitalize : "#{subdomain.capitalize} Council"
  end

  def formatted_subdomain
    plan_x? ? council_code : subdomain.capitalize
  end

  def document_checklist?
    I18n.exists?("council_documents.#{subdomain}.document_checklist")
  end

  private

  def council_code_exists
    return true if plan_x?
    return true unless council_code_changed?

    errors.add(:council_code, "Please enter a valid council code") unless council_code == planning_data
  end

  def plan_x?
    council_code == "PlanX"
  end

  def planning_data
    @planning_data ||= Apis::PlanningData::Query.new.council_code(council_code)
  end

  def planning_data?
    !planning_data.nil?
  end
end
