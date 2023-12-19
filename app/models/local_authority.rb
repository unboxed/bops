# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  with_options dependent: :destroy do
    has_many :users
    has_many :planning_applications
    has_many :constraints
    has_many :api_users
  end

  has_many :audits, through: :planning_applications

  with_options presence: true do
    validates :council_code, :subdomain
    validates :short_name, :council_name
    validates :applicants_url, :email_address
    validates :signatory_name, :signatory_job_title
    validates :enquiries_paragraph, :feedback_email
  end

  with_options format: {with: URI::HTTP::ABS_URI} do
    with_options allow_blank: true do
      validates :applicants_url
    end
  end

  with_options format: {with: URI::MailTo::EMAIL_REGEXP} do
    with_options allow_blank: true do
      validates :email_address
      validates :reviewer_group_email
      validates :press_notice_email
    end
  end

  validate :council_code_exists

  def signatory
    "#{signatory_name}, #{signatory_job_title}"
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
