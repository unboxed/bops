# frozen_string_literal: true

module SystemSpecHelpers
  def row_with_content(content, element = page)
    element.find("tr", text: content)
  end

  def selected_govuk_tab
    find("div[class='govuk-tabs__panel']")
  end

  def list_item(text, element = page)
    element.find("li", text:, match: :prefer_exact)
  end

  def find_checkbox_by_id(id)
    find(".govuk-checkboxes__item ##{id}")
  end

  def open_accordion_section
    find(:xpath, "//*[@class='govuk-accordion__section govuk-accordion__section--expanded']")
  end

  def expand_span_item(text)
    find("span", text:).click
  end
end
