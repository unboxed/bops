# frozen_string_literal: true

class Complainant
  def initialize(data)
    @data = data || {}
  end

  def name
    [@data.dig("name", "first"), @data.dig("name", "last")].compact.join(" ")
  end

  def email
    @data.dig("email")
  end

  def phone
    @data.dig("phone", "primary")
  end

  def address
    [
      @data.dig("address", "line1"),
      @data.dig("address", "town"),
      @data.dig("address", "postcode"),
      @data.dig("address", "country")
    ].compact.compact_blank.join(", ")
  end

  private

  def dig(*keys)
    @data.dig(*keys)
  end
end
