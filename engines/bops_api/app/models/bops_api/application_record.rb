# frozen_string_literal: true

module BopsApi
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
