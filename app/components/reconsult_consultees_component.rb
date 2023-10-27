# frozen_string_literal: true

class ReconsultConsulteesComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end

  private

  attr_reader :form
end
