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
    validates :applicants_url
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

  before_update :set_active

  def signatory
    "#{signatory_name}, #{signatory_job_title}"
  end

  def document_checklist?
    I18n.exists?("council_documents.#{subdomain}.document_checklist")
  end

  def notify_notion_link
    "https://oasis-marsupial-465.notion.site/Guide-to-Notify-set-up-7c18a8f3d43444d098c1f79eab48016c?pvs=74"
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

  def set_active
    self.active = active_attributes?
  end

  def active_attributes?
    attributes.select { |k, v| active_attributes.include?(k) }.values.all?(&:present?)
  end

  def active_attributes
    %w[signatory_name
      signatory_job_title
      enquiries_paragraph
      email_address
      feedback_email
      press_notice_email
      reviewer_group_email
      notify_api_key
      notify_letter_template
      reply_to_notify_id
      email_reply_to_id]
  end
end
