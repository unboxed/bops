# frozen_string_literal: true

class CommitteeDecision < ApplicationRecord
  belongs_to :planning_application

  has_many :reviews, -> { order(created_at: :desc, id: :desc) }, as: :owner, dependent: :destroy

  validates :recommend, exclusion: {in: [nil]}

  with_options on: :notification do
    validates :date_of_committee, :location, :link, :time, :late_comments_deadline,
      presence: {if: -> { review_complete? && planning_application_awaiting_determination? && recommend? }}
  end

  validate :ensure_planning_application_not_closed_or_cancelled

  accepts_nested_attributes_for :reviews

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
      content
    else
      super.presence
    end
  end

  def content
    "# #{header}\n\n#{body}"
  end

  def header
    planning_application.application_type.legislation_title
  end

  def body
    new_body = I18n.t("neighbour_letter_template.committee")

    defaults = {
      address: planning_application.full_address,
      council: planning_application.local_authority.short_name,
      reference: planning_application.reference,
      date_of_committee: planning_application.committee_decision.date_of_committee.to_date.to_fs,
      time: planning_application.committee_decision.time,
      location: planning_application.committee_decision.location,
      decision: planning_application.decision,
      link: planning_application.committee_decision.link,
      assigned_officer:,
      late_comments_deadline: planning_application.committee_decision.late_comments_deadline.to_date.to_fs,
      application_link:
    }

    replace_placeholders(new_body, defaults)
  end

  def current_review
    reviews.load.first || reviews.create!
  end

  def all_details_present?
    location.present? &&
      link.present? &&
      time.present? &&
      date_of_committee.present? &&
      late_comments_deadline.present?
  end

  def rejected_review?
    current_review.rejected?
  end

  def update_review(params)
    case params[:status]
    when "complete"
      mark_as_complete(params)
    when "in_progress"
      mark_as_in_progress(params)
    else
      raise ArgumentError, "Unexpected review status: #{params[:status].inspect}"
    end
  end

  private

  def mark_as_complete(params)
    if current_review.to_be_reviewed?
      reviews.create!(params.merge(status: "updated"))
    else
      current_review.update!(params)
    end
  rescue ActiveRecord::ActiveRecordError
    false
  end

  def mark_as_in_progress(params)
    if current_review.to_be_reviewed?
      current_review.update!(params.except(:status))
    else
      current_review.update!(params)
    end
  rescue ActiveRecord::ActiveRecordError
    false
  end

  def assigned_officer
    planning_application.user.present? ? planning_application.user.name : Current.user.name
  end

  def replace_placeholders(string, variables)
    string.to_s.gsub(EMAIL_PLACEHOLDER) { variables.fetch($1.to_sym) }
  end

  def application_link
    "#{planning_application.local_authority.applicants_url}/planning_applications/#{planning_application.reference}"
  end

  def review_complete?
    current_review.review_complete?
  end

  def planning_application_awaiting_determination?
    planning_application.awaiting_determination?
  end

  def ensure_planning_application_not_closed_or_cancelled
    errors.add(:base, "Cannot modify committee decision when planning application has been closed or cancelled") if planning_application.closed_or_cancelled?
  end
end
