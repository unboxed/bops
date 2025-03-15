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

  def expand_span_item(text)
    find("span", text:).click
  end

  def with_retry(delay: 0.1, count: 3)
    retries = 0

    begin
      yield
    rescue => error
      if retries < count
        retries += 1
        sleep delay
        retry
      else
        raise error
      end
    end
  end

  def pick(value, from:)
    listbox = "ul[@id='#{from.delete_prefix("#")}__listbox']"
    option = "li[@role='option' and normalize-space(.)='#{value}']"

    with_retry do
      find(:xpath, "//#{listbox}/#{option}").click
    end

    # The autocomplete javascript has some setTimeout handlers
    # to work around bugs with event order so we need to wait
    sleep 0.1
  end

  def toggle(summary)
    find(:xpath, "//details/summary[contains(., '#{summary}')]").click
  end
end
