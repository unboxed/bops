# frozen_string_literal: true

class CommitteeDecision < ApplicationRecord
  belongs_to :planning_application

  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  validates :recommend, exclusion: {in: [nil]}

  validates :date_of_committee, :location, :link, :time, :late_comments_deadline, presence: {if: -> { planning_application_not_in_assessment? && recommend? }}

  after_update :create_review, if: :should_create_review?

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
    "Town and Country Planning Act 1990"
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
      application_link: application_link(planning_application)
    }

    replace_placeholders(new_body, defaults)
  end

  def current_review
    reviews.order(:created_at).last
  end

  private

  def assigned_officer
    planning_application.user.present? ? planning_application.user.name : Current.user.name
  end

  def replace_placeholders(string, variables)
    string.to_s.gsub(EMAIL_PLACEHOLDER) { variables.fetch($1.to_sym) }
  end

  def application_link(planning_application)
    "#{planning_application.local_authority.applicants_url}/planning_applications/#{planning_application.id}"
  end

  def planning_application_not_in_assessment?
    planning_application.awaiting_determination? || planning_application.in_committee?
  end

  def should_create_review?
    return if current_review.nil?
    current_review.status == "updated" && current_review.review_status == "to_be_reviewed"
  end

  def create_review
    reviews.create!(assessor: Current.user, owner_type: "CommitteeDecision", owner_id: id, status: "complete")
  end
end
