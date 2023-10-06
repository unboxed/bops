# frozen_string_literal: true

class ReviewAssessmentDetailsForm
  include Memoizable
  include ActiveModel::Model
  extend ActiveModel::Callbacks

  LDC_ASSESSMENT_DETAILS = %i[
    summary_of_work
    site_description
    consultation_summary
    additional_evidence
  ].freeze

  PRIOR_APPROVAL_ASSESSMENT_DETAILS = %i[
    summary_of_work
    site_description
    additional_evidence
    publicity_summary
    amenity
  ].freeze

  PLANNING_PERMISSION_ASSESSMENT_DETAILS = %i[
    summary_of_work
    site_description
    additional_evidence
    consultation_summary
    publicity_summary
  ].freeze

  ASSESSMENT_DETAILS = %i[
    summary_of_work
    site_description
    consultation_summary
    additional_evidence
    publicity_summary
    amenity
  ].freeze

  define_model_callbacks :save

  attr_accessor :planning_application, :status

  validate :recommendation_not_accepted

  before_save :set_statuses

  ASSESSMENT_DETAILS.each do |assessment_detail|
    define_method(assessment_detail) do
      memoize(
        assessment_detail,
        planning_application.send("existing_or_new_#{assessment_detail}")
      )
    end

    define_method("#{assessment_detail}_comment") do
      memoize(
        "#{assessment_detail}_comment",
        send(assessment_detail).existing_or_new_comment
      )
    end

    delegate(
      :reviewer_verdict,
      "reviewer_verdict=",
      :entry,
      "entry=",
      to: assessment_detail,
      prefix: true
    )

    delegate(:text, "text=", to: "#{assessment_detail}_comment", prefix: true)

    validates(
      "#{assessment_detail}_reviewer_verdict",
      presence: true,
      if: :status_complete? && :"#{assessment_detail}_for_application?"
    )

    validates(
      "#{assessment_detail}_comment_text",
      presence: true,
      if: "#{assessment_detail}_reviewer_verdict_rejected?".to_sym
    )

    validates(
      "#{assessment_detail}_entry",
      presence: true,
      if: "#{assessment_detail}_reviewer_verdict_edited_and_accepted?".to_sym
    )

    validate(
      "#{assessment_detail}_entry_changed".to_sym,
      if: "#{assessment_detail}_reviewer_verdict_edited_and_accepted?".to_sym
    )

    define_method("#{assessment_detail}_reviewer_verdict_rejected?") do
      send("#{assessment_detail}_reviewer_verdict") == "rejected"
    end

    define_method("#{assessment_detail}_reviewer_verdict_edited_and_accepted?") do
      send("#{assessment_detail}_reviewer_verdict") == "edited_and_accepted"
    end

    define_method("#{assessment_detail}_entry_changed") do
      return if !send(assessment_detail).reviewer_verdict_changed? || send(assessment_detail).entry_changed?

      errors.add("#{assessment_detail}_entry", :not_changed)
    end
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      run_callbacks :save do
        assessment_details.each do |assessment_detail|
          next if assessment_detail.reviewer_verdict.blank?

          assessment_detail.save!
        end
      end
    end

    true
  end

  def assessment_detail_types
    case planning_application.application_type.name.to_sym
    when :lawfulness_certificate
      LDC_ASSESSMENT_DETAILS
    when :prior_approval
      PRIOR_APPROVAL_ASSESSMENT_DETAILS
    else
      PLANNING_PERMISSION_ASSESSMENT_DETAILS
    end
  end

  private

  def recommendation_not_accepted
    return unless planning_application.last_recommendation_accepted?

    errors.add(:base, :recommendation_accepted)
  end

  def set_statuses
    assessment_details.each do |assessment_detail|
      assessment_detail.review_status = status
    end
  end

  def assessment_details
    ASSESSMENT_DETAILS.map { |assessment_detail| send(assessment_detail) }
  end

  def status_complete?
    status == :complete
  end

  ASSESSMENT_DETAILS.each do |assessment_detail|
    define_method("#{assessment_detail}_for_application?") do
      next if status == :in_progress

      case planning_application.type
      when "Lawful Development Certificate"
        LDC_ASSESSMENT_DETAILS.include? assessment_detail
      when "Prior approval"
        PRIOR_APPROVAL_ASSESSMENT_DETAILS.include? assessment_detail
      when "Householder Application for Planning Permission"
        PLANNING_PERMISSION_ASSESSMENT_DETAILS.include? assessment_detail
      end
    end
  end
end
