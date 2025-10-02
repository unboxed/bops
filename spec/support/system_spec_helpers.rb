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

  def toggle(title)
    selectors = [
      ".//span[@class='govuk-accordion__section-button' and contains(., '#{title}')]",
      ".//button[@class='govuk-accordion__section-button' and contains(., '#{title}')]",
      ".//details/summary[contains(., '#{title}')]"
    ]

    node = find(:xpath, selectors.join("|"))

    if node.tag_name == "span"
      # For rack-test we need to manually add the
      # CSS class to expand the accordion
      parent_selector = ".//ancestor-or-self::*[@class='govuk-accordion__section']"
      parent_node = node.find(:xpath, parent_selector)
      expanded_class = "govuk-accordion__section--expanded"
      native_node = parent_node.native

      if native_node.classes.include?(expanded_class)
        native_node.remove_class(expanded_class)
      else
        native_node.add_class(expanded_class)
      end
    else
      # This is either a summary or button so we
      # can rely on the standard click behaviour
      node.click
    end
  end

  def on_subdomain(subdomain)
    previous_app_host = Capybara.app_host
    Capybara.app_host = "http://#{subdomain}.bops.services"

    yield
  ensure
    Capybara.app_host = previous_app_host
  end
end
