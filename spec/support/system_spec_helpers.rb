# frozen_string_literal: true

module SystemSpecHelpers
  def row_with_content(content, element = page)
    element.find("tr", text: content)
  end

  def selected_govuk_tab
    find("div[class='govuk-tabs__panel']:not(.govuk-tabs__panel--hidden)")
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

  def pick(value, from:)
    listbox = "ul[@id='#{from.delete_prefix("#")}__listbox']"
    option = "li[@role='option' and normalize-space(.)='#{value}']"

    find(:xpath, "//#{listbox}/#{option}").click

    # The autocomplete javascript has some setTimeout handlers
    # to work around bugs with event order so we need to wait
    sleep 0.1
  end

  def toggle(summary)
    find(:xpath, "//details/summary[contains(., '#{summary}')]").click
  end
end
