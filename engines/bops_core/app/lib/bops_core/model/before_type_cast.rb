# frozen_string_literal: true

module BopsCore
  module Model
    module BeforeTypeCast
      extend ActiveSupport::Concern

      included do
        attribute_method_suffix "_before_type_cast", "_for_database"
        attribute_method_suffix "_came_from_user?"
      end

      def attributes_before_type_cast
        @attributes.values_before_type_cast
      end

      private

      def attribute_before_type_cast(attr_name)
        @attributes[attr_name].value_before_type_cast
      end

      def attribute_for_database(attr_name)
        @attributes[attr_name].value_for_database
      end

      def attribute_came_from_user?(attr_name)
        @attributes[attr_name].came_from_user?
      end
    end
  end
end
