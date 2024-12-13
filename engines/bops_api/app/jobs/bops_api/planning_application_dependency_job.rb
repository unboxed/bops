# frozen_string_literal: true

require "faraday"
require "uri"

module BopsApi
  class PlanningApplicationDependencyJob < ApplicationJob
    queue_as :submissions

    retry_on(StandardError, attempts: 5, wait: 2.minutes, jitter: 0) do |_, error|
      Appsignal.report_error(error)
    end

    retry_on(Faraday::TimeoutError, attempts: 5, wait: 2.minutes, jitter: 0) do |_, error|
      Appsignal.report_error(error)
    end

    def document_checklist_items
      @document_checklist_items ||= params.dig(:metadata, :service, :files)
    end

    def perform(planning_application:, user:, files:, params:, email_sending_permitted:)
      @user = user
      @params = params

      Application::AnonymisationService.new(planning_application:).call! if planning_application.from_production?
      process_document_checklist_items(planning_application)
      Application::DocumentsService.new(planning_application:, user:, files:).call!

      process_planning_designations(planning_application)
      process_ownership_certificate_details(planning_application)
      process_immunity_details(planning_application) if possibly_immune?(planning_application)
      process_preapplication_services(planning_application) if planning_application.pre_application?

      if planning_application.pending?
        planning_application.mark_accepted!
        planning_application.send_receipt_notice_mail if email_sending_permitted
      end
    end

    private

    attr_reader :user, :params

    def data_params
      @data_params ||= params.fetch(:data)
    end

    def process_document_checklist_items(planning_application)
      document_checklist = DocumentChecklist.create!(planning_application:)

      document_checklist_items.each do |category, document_item|
        document_item.each do |document|
          if document.is_a?(Hash)
            tags = document["value"]
            description = document["description"]
          elsif document.is_a?(String)
            tags = document
            description = document
          else
            raise "Unexpected document type when reading checklist items"
          end

          document_checklist.document_checklist_items.create!(category:, tags:, description:)
        end
      end
    end

    def create_planning_application_constraint(planning_application, designation, constraint)
      planning_application.planning_application_constraints.create! do |c|
        c.constraint = constraint
        c.identified = true
        c.identified_by = user.service
        c.data = []
        c.metadata = {"description" => designation.fetch(:description)}
      end
    end

    def process_planning_designations(planning_application)
      planning_designations.each do |designation|
        next unless designation.fetch(:intersects)

        if (constraint = ::Constraint.for_type(designation.fetch(:value)))
          planning_application_constraint = if planning_application.planning_application_constraints.find_by(constraint_id: constraint.id)&.pending?
            planning_application.planning_application_constraints.find_by(constraint: constraint)
          else
            create_planning_application_constraint(planning_application, designation, constraint)
          end

          entities = designation.fetch(:entities, [])

          if entities.present?
            fetch_constraint_entities(planning_application_constraint, entities)
          end
        end
      end
    end

    def planning_designations
      Array.wrap(data_params.dig(:property, :planning, :designations))
    end

    def process_ownership_certificate_details(planning_application)
      return unless data_params[:applicant].key?(:ownership)
      ownership_details = data_params[:applicant][:ownership]
      return unless ownership_details.key?(:certificate)

      ActiveRecord::Base.transaction do
        ownership_certificate = OwnershipCertificate.create!(planning_application:, certificate_type: ownership_details[:certificate])

        if ownership_details[:owners].present?
          ownership_details[:owners].each do |owner|
            LandOwner.create(
              ownership_certificate:,
              name: owner[:name],
              town: owner[:address][:town],
              address_1: owner[:address][:line1],
              address_2: owner[:address][:line2],
              county: owner[:address][:county],
              country: owner[:address][:country],
              postcode: owner[:address][:postcode],
              notice_given: owner[:noticeDate].present?,
              notice_given_at: owner[:noticeDate],
              notice_reason: owner[:noticeReason]
            )
          end
        end
      end
    end

    def possibly_immune?(planning_application)
      planning_application.immune_proposal_details.many?
    end

    def process_immunity_details(planning_application)
      ActiveRecord::Base.transaction do
        immunity_detail = ImmunityDetail.new(planning_application: planning_application)

        immunity_detail.end_date = params.dig("data", "proposal", "date", "completion")
        immunity_detail.end_date ||= planning_application
          .find_proposal_detail("When were the works completed?")
          .first.response_values.first
        immunity_detail.save!
      end

      Document::EVIDENCE_TAGS.each do |tag|
        next if planning_application.documents.with_tag(tag).empty?

        planning_application.documents.with_tag(tag).each do |doc|
          planning_application.immunity_detail.add_document(doc)
        end
      end

      planning_application.immunity_detail.evidence_groups.each do |eg|
        Document::EVIDENCE_QUESTIONS[eg.tag.to_sym].each do |question|
          value = planning_application.find_proposal_detail(question).first&.response_values&.first

          case question
          when /show/
            eg.applicant_comment = value
          when /(start|issued)/
            eg.start_date = value
          when /run/
            eg.end_date = value
          end
          eg.save!
        end
      end
    rescue ActiveRecord::RecordInvalid, NoMethodError => e
      Appsignal.report_error(e)
    end

    def process_preapplication_services(planning_application)
      questions = planning_application.find_proposal_detail("Planning Pre-Application Advice Services")
      responses = questions.map(&:response_values).flatten

      responses.each do |response|
        name = case response
        when /written advice/i
          :written_advice
        when /meeting/i
          :meeting
        when /visit/i
          :site_visit
        end

        planning_application.additional_services << PreapplicationService.new(name:)
      end
    end

    def fetch_constraint_entities(planning_application_constraint, entities)
      planning_application_constraint.update!(data: fetch_entities(entities), status: "success")
    rescue BopsApi::Errors::EntityNotFoundError
      planning_application_constraint.update!(data: [], status: "not_found")
    rescue BopsApi::Errors::EntityRemovedError
      planning_application_constraint.update!(data: [], status: "removed")
    rescue BopsApi::Errors::EntityFetchFailedError
      planning_application_constraint.update!(data: [], status: "failed")
    end

    def fetch_entities(entities)
      entities.map { |entity| fetch_entity(entity.fetch(:source)) }.compact
    end

    def fetch_entity(source)
      uri = normalise_url(source)

      raise BopsApi::Errors::EntityFetchFailedError unless uri

      connection = Faraday.new(uri.origin) do |faraday|
        faraday.response :json, content_type: /\bjson$/
      end

      response = connection.get(uri.request_uri)

      case response.status
      when 200
        if response.body.is_a?(Hash)
          response.body
        else
          raise BopsApi::Errors::InvalidEntityResponseError, "Request for entity #{uri} returned a non-JSON response"
        end
      when 204
        nil
      when 404
        raise BopsApi::Errors::EntityNotFoundError, "Entity #{uri} was not found"
      when 410
        raise BopsApi::Errors::EntityRemovedError, "Entity #{uri} has been removed"
      else
        raise BopsApi::Errors::EntityFetchFailedError, "Entity #{uri} could not be fetched"
      end
    rescue Faraday::Error
      raise BopsApi::Errors::EntityFetchFailedError, "Entity #{uri} could not be fetched"
    end

    def normalise_url(source)
      if source.is_a? Hash
        source = source[:url]
      end

      return unless source

      mappings = {
        "planning.data.gov.uk" => "www.planning.data.gov.uk"
      }

      uri = URI.parse("#{source}.json")

      uri.host = mappings.fetch(uri.host, uri.host)

      return unless uri.host == "www.planning.data.gov.uk"

      uri
    end
  end
end
