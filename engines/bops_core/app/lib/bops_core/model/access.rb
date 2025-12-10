# frozen_string_literal: true

module BopsCore
  module Model
    module Access
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix "_before_type_cast", "_for_database"
        attribute_method_suffix "_came_from_user?"
      end

      def [](key)
        attribute(key)
      end

      def []=(name, value)
        _write_attribute(name, value)
      end
    end
  end
end
