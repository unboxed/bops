# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  include Pagy::UrlHelpers

  def initialize(pagy:)
    @pagy = pagy
  end

  private

  attr_reader :pagy

  def page_url(page)
    pagy_url_for(pagy, page)
  end

  def wrapper_tag(&)
    options = {
      class: "govuk-pagination",
      role: "navigation",
      aria: {
        label: "Pagination"
      }
    }

    content_tag(:nav, options, &)
  end

  def list_tag(&)
    content_tag(:ul, class: "govuk-pagination__list", &)
  end

  def prev_tag(&)
    return unless pagy.prev

    content_tag(:div, class: "govuk-pagination__prev", &)
  end

  def prev_link(&)
    options = {
      class: "govuk-link govuk-pagination__link govuk-link--no-visited-state",
      rel: "prev"
    }

    link_to(page_url(pagy.prev), options, &)
  end

  def next_tag(&)
    return unless pagy.next

    content_tag(:div, class: "govuk-pagination__next", &)
  end

  def next_link(&)
    options = {
      class: "govuk-link govuk-pagination__link govuk-link--no-visited-state",
      rel: "next"
    }

    link_to(page_url(pagy.next), options, &)
  end

  def items
    pagy.series(size: [1, 2, 2, 1])
  end

  def item_tag(item)
    case item
    when Integer
      page_item(item)
    when String
      current_item(item)
    when :gap
      gap_item
    else
      raise ArgumentError, "Invalid pagination item: #{item.inspect}"
    end
  end

  def item_wrapper(content, extra = nil)
    options = {
      class: class_names("govuk-pagination__item", extra)
    }

    content_tag(:li, content, options)
  end

  def gap_item
    item_wrapper("…", "govuk-pagination__item--ellipses")
  end

  def page_link(page, **options)
    defaults = {
      class: "govuk-link govuk-pagination__link",
      aria: {
        label: "Page #{page}"
      }
    }

    link_to(page.to_s, page_url(page), defaults.deep_merge(options))
  end

  def page_item(page)
    item_wrapper(page_link(page))
  end

  def current_link(page)
    page_link(page.to_i, aria: {current: "page"})
  end

  def current_item(page)
    item_wrapper(current_link(page), "govuk-pagination__item--current")
  end
end
