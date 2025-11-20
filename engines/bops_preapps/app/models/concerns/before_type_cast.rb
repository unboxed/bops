module BeforeTypeCast
  extend ActiveSupport::Concern

  included do
    attribute_method_suffix "_before_type_cast"
  end

  def attributes_before_type_cast
    @attributes.values_before_type_cast
  end

  private

  def attribute_before_type_cast(attr_name)
    @attributes[attr_name].value_before_type_cast
  end

end