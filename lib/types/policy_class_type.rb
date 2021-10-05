# frozen_string_literal: true

class PolicyClassType < ActiveRecord::Type::Json
  def type
    :policy_class_type
  end

  def deserialize(value)
    PolicyClass.new(super)
  end
end
