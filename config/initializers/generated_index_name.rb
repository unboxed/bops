# frozen_string_literal: true

# make indexes shorter for postgres
require "active_record/connection_adapters/abstract/schema_statements"
module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      def index_name(table_name, options) # :nodoc:
        if options.is_a?(Hash)
          if options[:column]
            "ix_#{table_name}_on_#{Array(options[:column]) * "__"}".slice(0, 63)
          elsif options[:name]
            options[:name]
          else
            raise ArgumentError, "You must specify the index name"
          end
        else
          index_name(table_name, index_name_options(options))
        end
      end
    end
  end
end
