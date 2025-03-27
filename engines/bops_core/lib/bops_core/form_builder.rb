# frozen_string_literal: true

require "govuk_design_system_formbuilder"
require "bops_core/form_elements/rich_text_area"

module BopsCore
  class FormBuilder < GOVUKDesignSystemFormBuilder::FormBuilder
    def govuk_rich_text_area(attribute_name, hint: {}, label: {}, caption: {}, form_group: {}, **, &)
      FormElements::RichTextArea.new(self, object_name, attribute_name, hint:, label:, caption:, form_group:, **, &).html
    end
  end
end
