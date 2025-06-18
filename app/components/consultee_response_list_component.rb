# frozen_string_literal: true

class ConsulteeResponseListComponent < ViewComponent::Base
  def initialize(responses:, redact_and_publish:)
    @responses = responses.select(&:persisted?)
    @redact_and_publish = redact_and_publish
  end

  private

  attr_reader :responses, :redact_and_publish
end
