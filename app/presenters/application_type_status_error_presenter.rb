# frozen_string_literal: true

class ApplicationTypeStatusErrorPresenter < ErrorPresenter
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper

  private

  def link_tag(text)
    options = {
      class: "govuk-link",
      href: BopsConfig::Engine.routes.url_helpers.edit_application_type_legislation_path(record)
    }

    content_tag(:a, text, **options)
  end

  def link?
    true
  end
end
