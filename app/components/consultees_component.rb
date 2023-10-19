# frozen_string_literal: true

class ConsulteesComponent < ViewComponent::Base
  def initialize(consultees:, form:)
    @consultees = consultees
    @form = form
  end

  private

  attr_reader :consultees, :form
end
