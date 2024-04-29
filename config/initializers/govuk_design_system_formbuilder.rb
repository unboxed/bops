# frozen_string_literal: true

require "govuk_design_system_formbuilder"

GOVUKDesignSystemFormBuilder.configure do |conf|
  conf.default_submit_button_text = "Save"

  Rails.application.config.to_prepare do
    conf.default_error_summary_presenter = ErrorPresenter
  end
end
