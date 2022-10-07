# frozen_string_literal: true

module SystemSpecHelpers
  def row_with_content(content, element = page)
    element.find_all("tr").find { |tr| tr.has_content?(content) }
  end

  def selected_govuk_tab
    find("div[class='govuk-tabs__panel']")
  end

  def list_item(text)
    find("li", text: text)
  end
end
