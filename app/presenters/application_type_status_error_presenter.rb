# frozen_string_literal: true

class ApplicationTypeStatusErrorPresenter < ErrorPresenter
  include Rails.application.routes.url_helpers
  include Rails.application.routes.mounted_helpers
  include ActionView::Helpers::TagHelper

  private

  def link_tag(text, attribute)
    content_tag(:a, text, href: href_for(attribute), class: "govuk-link")
  end

  def href_for(attribute)
    case attribute
    when :legislation
      bops_config.edit_application_type_legislation_path(record)
    when :reporting_types
      bops_config.edit_application_type_reporting_path(record)
    when :category
      bops_config.edit_application_type_category_path(record)
    else
      bops_config.application_type_path(record)
    end
  end

  def link?
    true
  end
end
