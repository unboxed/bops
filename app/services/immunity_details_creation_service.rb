# frozen_string_literal: true

class ImmunityDetailsCreationService
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  def call
    ActiveRecord::Base.transaction do
      immunity_detail = ImmunityDetail.new(planning_application: @planning_application)
      immunity_detail.end_date = application_end_date
      immunity_detail.save!
    end
    create_evidence_groups
    fill_in_evidence_group_information
  rescue ActiveRecord::RecordInvalid, NoMethodError => e
    Appsignal.send_error(e)
  end

  private

  attr_reader :planning_application

  def application_end_date
    @planning_application.find_proposal_detail("When were the works completed?").first.response_values.first
  end

  def create_evidence_groups
    Document::EVIDENCE_TAGS.each do |tag|
      next if @planning_application.documents.with_tag(tag).empty?

      @planning_application.documents.with_tag(tag).each do |doc|
        @planning_application.immunity_detail.add_document(doc)
      end
    end
  end

  def fill_in_evidence_group_information # rubocop:disable Metrics/AbcSize
    @planning_application.immunity_detail.evidence_groups.each do |eg|
      Document::EVIDENCE_QUESTIONS[eg.tag.to_sym].each do |question|
        case question
        when /show/
          eg.applicant_comment = @planning_application.find_proposal_detail(question).first.response_values.first
        when /(start|issued)/
          eg.start_date = @planning_application.find_proposal_detail(question).first.response_values.first
        when /run/
          eg.end_date = @planning_application.find_proposal_detail(question).first.response_values.first
        end
        eg.save!
      end
    end
  end
end
