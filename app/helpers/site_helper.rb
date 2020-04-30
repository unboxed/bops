# frozen_string_literal: true

module SiteHelper
  def display_address(site)
    "#{site.address_1}, #{site.town}, #{site.postcode}"
  end
end
