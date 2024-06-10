# frozen_string_literal: true

class FormattedContentComponent < ViewComponent::Base
  ALLOWED_ATTRIBUTES = %w[href target data-controller data-action].freeze

  def initialize(text:, title: nil, classname: nil, data_attributes: {})
    @text = text
    @title = title
    @classname = classname || "govuk-body"
    @data_attributes = data_attributes
  end

  def auto_link_and_simple_format
    sanitize(simple_format_content, attributes: allowed_attributes)
  end

  private

  attr_reader :text, :title, :classname, :data_attributes

  def allowed_attributes
    Rails::Html::Sanitizer.white_list_sanitizer.allowed_attributes + ALLOWED_ATTRIBUTES
  end

  def simple_format_content
    simple_format(auto_link_content, {class: classname, **data_attributes}, sanitize: false)
  end

  def auto_link_content
    auto_link(content, html: {target: "_blank"}, sanitize: false)
  end

  def content
    if title
      "#{tag.strong("#{title}:")} #{text}"
    else
      text.to_s
    end
  end
end
