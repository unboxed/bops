# frozen_string_literal: true

module SystemSpecHelpers
  def row_with_content(content, element = page)
    element.find_all("tr").find { |tr| tr.has_content?(content) }
  end
end
