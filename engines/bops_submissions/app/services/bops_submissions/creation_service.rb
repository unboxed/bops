# frozen_string_literal: true

module BopsSubmissions
  class CreationService
    def initialize(request:, local_authority:)
      @request = request
      @local_authority = local_authority
    end

    attr_reader :request, :local_authority

    def call
      submission = local_authority.submissions.create!(
        request_headers: request_headers,
        request_body: permitted_request_params
      )

      submission.update!(external_uuid: SecureRandom.uuid_v7)
      # SubmissionProcessorJob.perform_later(submission.id)

      uuid
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(', '), :unprocessable_entity)
    end

    private

    def permitted_request_params
      @request.params.permit(
        :applicationRef,
        :applicationVersion,
        :applicationState,
        :sentDateTime,
        :updated,
        documentLinks: [:documentName, :documentLink, :expiryDateTime, :documentType]
      ).to_h
    end

    def request_headers
      @request.headers
    end
  end
end
