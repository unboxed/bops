# frozen_string_literal: true

class ConsulteeResponseListComponent < ViewComponent::Base
  def initialize(responses:)
    @responses = responses
  end

  private

  attr_reader :responses
end
