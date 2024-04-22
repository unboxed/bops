# frozen_string_literal: true

module BopsCore
  module AuditableModel
    extend ActiveSupport::Concern
    include Auditable

    included do
      with_options instance_accessor: false do
        class_attribute :audit_attributes, default: %w[id]
        class_attribute :audit_changes, default: %w[created_at updated_at]
      end
    end

    def audit_attributes
      attributes.slice(*self.class.audit_attributes)
    end

    def audit_changes
      previous_changes.except(*self.class.audit_changes)
    end
  end
end
