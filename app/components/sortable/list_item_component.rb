# frozen_string_literal: true

module Sortable
  class ListItemComponent < ViewComponent::Base
    include ConditionsHelper

    def initialize(record:, record_class:, record_controller:, record_sortable_url:, edit_record_url:, remove_record_url: nil, current_request: nil, show_status_tag: true)
      @record = record
      @record_class = record_class
      @record_controller = record_controller
      @record_sortable_url = record_sortable_url
      @edit_record_url = edit_record_url
      @remove_record_url = remove_record_url
      @current_request = current_request
      @show_status_tag = show_status_tag
    end

    attr_reader :show_status_tag

    private

    attr_reader :record, :record_class, :record_controller, :record_sortable_url, :edit_record_url, :remove_record_url, :current_request

    def caption_text
      if record.is_a?(Condition) && !record.condition_set.pre_commencement? && record.standard?
        "Suggested condition"
      elsif record.is_a?(Term)
        "Heads of term"
      else
        record_class.capitalize.to_s
      end
    end

    def full_caption_text
      "#{caption_text} #{record.position}"
    end

    def remove_link
      return if remove_record_url.blank?

      govuk_link_to(
        "Remove",
        remove_record_url,
        method: :delete,
        data: {confirm: "Are you sure?"}
      )
    end

    def edit_link
      govuk_link_to("Edit", edit_record_url)
    end

    def cancel_link
      return if current_request.blank?

      govuk_link_to(
        "Cancel",
        cancel_confirmation_planning_application_validation_validation_request_path(current_request.planning_application, current_request)
      )
    end
  end
end
