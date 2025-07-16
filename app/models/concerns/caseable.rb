# frozen_string_literal: true

module Caseable
  extend ActiveSupport::Concern

  included do
    has_one :case_record, as: :caseable, touch: true, dependent: :destroy
    delegate :local_authority, to: :case_record
    delegate :submission, to: :case_record
    delegate :user, to: :case_record
  end
end
