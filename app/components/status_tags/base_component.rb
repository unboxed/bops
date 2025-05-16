# frozen_string_literal: true

module StatusTags
  class BaseComponent < ViewComponent::Base
    def initialize(status:, html_attributes: {})
      @status = status
      @html_attributes = html_attributes
    end

    def render?
      status.present?
    end

    def call
      govuk_tag(text: link_text, colour:, html_attributes: @html_attributes.merge({class: "#{@html_attributes[:class]} govuk-tag--status-#{status}"}))
    end

    private

    attr_reader :status

    def link_text
      t("status_tag_component.#{status}")
    end

    def colour
      case status.to_sym
      when :approved, :auto_approved, :supportive, :complies
        "green"
      when :not_started, :new, :review_not_started, :not_consulted, :none, :no_response
        "blue"
      when :in_progress, :awaiting_response, :to_be_determined
        "light-blue"
      when :updated, :to_be_reviewed, :submitted, :neutral, :amendments_needed, :awaiting_changes
        "yellow"
      when :refused, :removed, :invalid, :rejected, :objection, :failed, :refused_legal_agreement, :cancelled, :does_not_comply
        "red"
      when :cannot_start_yet
        "grey"
      end
    end
  end
end
