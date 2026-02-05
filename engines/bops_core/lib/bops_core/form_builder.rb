# frozen_string_literal: true

require "govuk_design_system_formbuilder"
require "bops_core/form_elements/rich_text_area"

module BopsCore
  class FormBuilder < GOVUKDesignSystemFormBuilder::FormBuilder
    def govuk_rich_text_area(attribute_name, hint: {}, label: {}, caption: {}, form_group: {}, **, &)
      FormElements::RichTextArea.new(self, object_name, attribute_name, hint:, label:, caption:, form_group:, **, &).html
    end

    def govuk_task_button(text = nil, action: "save_and_complete", **kwargs, &block)
      govuk_submit(text, name: "task_action", value: action, **kwargs, &block)
    end

    def govuk_task_button_link(text = nil, action: "save_and_complete", **kwargs, &block)
      button(text, name: "task_action", value: action, class: "button-as-link", **kwargs, &block)
    end
  end
end
