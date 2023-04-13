# frozen_string_literal: true

module ImmunityDetailRightable
  extend ActiveSupport::Concern

  included do
    def immunity_detail_updated?
      !immunity_detail.review_not_started?
    end
  end
end
