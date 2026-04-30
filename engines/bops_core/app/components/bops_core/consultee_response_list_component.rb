# frozen_string_literal: true

module BopsCore
  class ConsulteeResponseListComponent < ViewComponent::Base
    def initialize(responses:, redact_and_publish:, task: nil)
      @responses = responses.select(&:persisted?)
      @redact_and_publish = redact_and_publish
      @task = task
    end

    private

    attr_reader :responses, :redact_and_publish, :task
  end
end
