# frozen_string_literal: true

module Memoizable
  extend ActiveSupport::Concern

  def memoize(key, value)
    instance_variable_get(:"@#{key}") || instance_variable_set(:"@#{key}", value)
  end
end
