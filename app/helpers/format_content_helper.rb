# frozen_string_literal: true

module FormatContentHelper
  def auto_link_and_simple_format_content(content:, classname: nil)
    allowed_attributes = Rails::Html::Sanitizer.white_list_sanitizer.allowed_attributes + %w[href target]

    auto_link_content = auto_link(content.to_s, html: { target: "_blank" }, sanitize: false)
    simple_format_content = simple_format(auto_link_content, { class: classname || "govuk-body" }, sanitize: false)

    sanitize(simple_format_content, attributes: allowed_attributes)
  end
end
