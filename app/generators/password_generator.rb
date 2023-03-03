# frozen_string_literal: true

class PasswordGenerator
  CAPITALS = ("A".."Z").to_a
  LETTERS = ("a".."z").to_a
  NUMBERS = ("0".."9").to_a
  SYMBOLS = %w[# ? ! @ $ % ^ & * -].freeze

  class << self
    def call
      (capitals + letters + numbers + symbols).shuffle.join
    end

    private

    def capitals
      CAPITALS.sample(4)
    end

    def letters
      LETTERS.sample(8)
    end

    def numbers
      NUMBERS.sample(2)
    end

    def symbols
      SYMBOLS.sample(2)
    end
  end
end
