# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  class << self
    def liquid_class
      @liquid_class ||= "#{name}Drop".constantize
    end
  end

  def update(attributes, context = nil)
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(context: context) # rubocop:disable Rails/SaveBang
    end
  end

  def update!(attributes, context = nil)
    with_transaction_returning_status do
      assign_attributes(attributes)
      save!(context: context)
    end
  end

  def to_liquid
    self.class.liquid_class.new(self)
  end
end
