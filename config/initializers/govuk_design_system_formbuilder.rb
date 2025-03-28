# frozen_string_literal: true

require "bops_core/form_builder"

Rails.application.config.to_prepare do
  GOVUKDesignSystemFormBuilder.configure do |conf|
    conf.default_submit_button_text = "Save"
    conf.default_error_summary_presenter = ErrorPresenter
  end

  ActionView::Base.default_form_builder = BopsCore::FormBuilder
end
