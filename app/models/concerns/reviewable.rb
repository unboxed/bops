# frozen_string_literal: true

module Reviewable
  extend ActiveSupport::Concern

  included do
    has_one :review, as: :reviewable, dependent: :destroy
  end
end
