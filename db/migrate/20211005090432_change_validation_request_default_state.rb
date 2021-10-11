# frozen_string_literal: true

class ChangeValidationRequestDefaultState < ActiveRecord::Migration[6.1]
  VALIDATION_REQUESTS = %w[
    description_change_validation_requests
    additional_document_validation_requests
    other_change_validation_requests
    red_line_boundary_change_validation_requests
    replacement_document_validation_requests
  ].freeze

  def each_validation_request_class
    VALIDATION_REQUESTS.each do |table_name|
      # Andrew said it was better to inherit ActiveRecord::Base here
      # rubocop:disable Rails/ApplicationRecord
      klass = Class.new(ActiveRecord::Base).tap { |t| t.table_name = table_name }
      # rubocop:enable Rails/ApplicationRecord

      yield(klass)
    end
  end

  def change
    reversible do |dir|
      dir.up do
        each_validation_request_class do |klass|
          klass.where(state: "open", notified_at: nil).update_all(state: "pending")

          change_table klass.table_name do |t|
            t.change_default :state, "pending"
          end
        end
      end

      dir.down do
        each_validation_request_class do |klass|
          klass.where(state: "pending").update_all(state: "open")

          change_table klass.table_name do |t|
            t.change_default :state, "open"
          end
        end
      end
    end
  end
end
