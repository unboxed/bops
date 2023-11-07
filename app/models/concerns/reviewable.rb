# frozen_string_literal: true

module Reviewable
  extend ActiveSupport::Concern

  included do
    has_one :review, as: :reviewable, autosave: true, dependent: :destroy
  end
end
